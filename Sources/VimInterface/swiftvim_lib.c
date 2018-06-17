#include <Python.h>
#include <execinfo.h>
#include <unistd.h>
#include <stdio.h>

// Do not export any symbols - we don't want collisions
#define VIM_INTEN __attribute__ ((visibility("hidden")))

static FILE *_plugin_error_f = NULL;

static FILE *plugin_error_f() {
    if (_plugin_error_f != NULL) {
        return _plugin_error_f;
    }

    static char template[] = "/private/tmp/swiftvim_stderr.logXXXXXX";
    char fname[PATH_MAX];
    char buf[BUFSIZ];
    strcpy(fname, template);
    mkstemp(fname);

    printf("logged errors to %s\n", fname);
    _plugin_error_f = fopen(fname, "w+");
    return _plugin_error_f;
}

/// Bridge PyString_AsString to both runtimes
static const char *SPyString_AsString(PyObject *input) {
#if PY_MAJOR_VERSION == 3
    return PyUnicode_AsUTF8(input);
#else
    return PyString_AsString(input);
#endif
}

/// Bridge PyString_FromString to both runtimes
static PyObject *SPyString_FromString(const char *input) {
#if PY_MAJOR_VERSION == 3
    return PyUnicode_FromString(input);
#else
    return PyString_FromString(input);
#endif
}
void *swiftvim_call_impl(void *func, void *arg1, void *arg2);

// module=vim, method=command|exec, str = value
VIM_INTEN void *swiftvim_call(const char *module, const char *method, const char *textArg) {
    PyObject *pName = SPyString_FromString(module);
    PyObject *pModule = PyImport_Import(pName);
    Py_DECREF(pName);
    if (pModule == NULL) {
        PyErr_Print();
        fprintf(plugin_error_f(), "swiftvim error: failed to load \"%s\"\n", module);
        return NULL;
    }

    PyObject *arg = SPyString_FromString(textArg);
    if (!arg) {
        fprintf(plugin_error_f(), "swiftvim error: Cannot convert argument\n");
        return NULL;
    }
    PyObject *pFunc = PyObject_GetAttrString(pModule, method);
    void *v = swiftvim_call_impl(pFunc, arg, NULL);
    Py_DECREF(pModule);
    Py_XDECREF(pFunc);
    return v;
}

VIM_INTEN void *swiftvim_get_module(const char *module) {
    PyObject *pName = SPyString_FromString(module);
    PyObject *pModule = PyImport_Import(pName);
    Py_DECREF(pName);
    if (pModule == NULL) {
        PyErr_Print();
        fprintf(plugin_error_f(), "swiftvim error: failed to load \"%s\"\n", module);
        return NULL;
    }
    return pModule;
}

VIM_INTEN void *swiftvim_get_attr(void *target, const char *method) {
    void *v = PyObject_GetAttrString(target, method);
    return v;
}

static void print_basic_error_desc() {
    // This goes to stderr, which vim can parse
    PyErr_Print();

    fprintf(plugin_error_f(), "\n=== startCallStack == \n");
    void *callstack[128];
    int frames = backtrace(callstack, 128);
    char **strs = backtrace_symbols(callstack, frames);
    for (int i = 0; i < frames; ++i) {
        fprintf(plugin_error_f(), "%s\n", strs[i]);
    }
    free(strs);
    fprintf(plugin_error_f(), "\n=== endCallStack == \n");
}

VIM_INTEN void *swiftvim_call_impl(void *pFunc, void *arg1, void *arg2) {
    void *outValue = NULL;
    // pFunc is a new reference 
    if (pFunc && PyCallable_Check(pFunc)) {
        int argCt = 0;
        if (arg1) {
            argCt++;
        }
        if (arg2) {
            argCt++;
        }

        PyObject *pArgs = PyTuple_New(argCt);
        /// Add args if needed
        if (arg1) {
            PyTuple_SetItem(pArgs, 0, arg1);
        }
        if (arg2) {
            PyTuple_SetItem(pArgs, 1, arg2);
        }
        PyObject *pValue = PyObject_CallObject(pFunc, pArgs);
        if (pValue != NULL) {
            outValue = pValue;
        } else {
            print_basic_error_desc();
            PyObject *funcObj = PyObject_Repr(pFunc);
            PyObject *arg1Obj = PyObject_Repr(arg1);
            PyObject *arg2Obj = PyObject_Repr(arg2);
            fprintf(plugin_error_f(),
                    "swiftvim error: call failed %s %s %s \n",
                    SPyString_AsString(funcObj),
                    SPyString_AsString(arg1Obj),
                    SPyString_AsString(arg2Obj));
        }
        Py_DECREF(pArgs);
    } else {
        print_basic_error_desc();
        PyObject *funcObj = PyObject_Repr(pFunc);
        fprintf(plugin_error_f(), "swiftvim error: cannot find function \"(%s)\"\n", SPyString_AsString(funcObj));
    }

    return outValue;
}

VIM_INTEN void *swiftvim_command(const char *command) {
    return swiftvim_call("vim", "command", command);
}

VIM_INTEN void *swiftvim_eval(const char *eval) {
    return swiftvim_call("vim", "eval", eval);
}

// TODO: Do these need GIL locks?
VIM_INTEN void *swiftvim_decref(void *value) {
    if (value == NULL) {
        return NULL;
    }

    Py_DECREF(value);
    return NULL;
}

VIM_INTEN void *swiftvim_incref(void *value) {
    if (value == NULL) {
        return NULL;
    }

    Py_INCREF(value);
    return NULL;
}

VIM_INTEN const char *swiftvim_asstring(void *value) {
    if (value == NULL) {
        return "";
    }
    const char *v = SPyString_AsString(value);
    return v;
}

VIM_INTEN long swiftvim_asnum(void *value) {
    int v = PyLong_AsLong(value);
    return v;
}

VIM_INTEN int swiftvim_list_size(void *list) {
    int v = PySequence_Size(list);
    return v;
}

VIM_INTEN void swiftvim_list_set(void *list, size_t i, void *value) {
    PySequence_SetItem(list, i, value);
}

VIM_INTEN void *swiftvim_list_get(void *list, size_t i) {
    /// Return a borrowed reference
    void *v = PySequence_GetItem(list, i);
    return v;
}

VIM_INTEN void swiftvim_list_append(void *list, void *value) {
    PyList_Append(list, value);
}

// MARK - Dict

VIM_INTEN int swiftvim_dict_size(void *dict) {
    int v = PyDict_Size(dict);
    return v;
}

VIM_INTEN void *swiftvim_dict_keys(void *dict) {
    // Return value: New reference
    void *v = PyDict_Keys(dict);
    return v;
}

VIM_INTEN void *swiftvim_dict_values(void *dict) {
    // Return value: New reference
    void *v = PyDict_Items(dict);
    return v;
}

VIM_INTEN void swiftvim_dict_set(void *dict, void *key, void *value) {
    PyDict_SetItem(dict, key, value);
}

VIM_INTEN void *swiftvim_dict_get(void *dict, void *key) {
    /// Return a borrowed reference
    void *v = PyDict_GetItem(dict, key);
    return v;
}

VIM_INTEN void swiftvim_dict_setstr(void *dict, const char *key, void *value) {
    PyDict_SetItemString(dict, key, value);
}

VIM_INTEN void *swiftvim_dict_getstr(void *dict, const char *key) {
    /// Return a borrowed reference
    void *v = PyDict_GetItemString(dict, key);
    return v;
}

// MARK - Tuples

VIM_INTEN void *_Nonnull swiftvim_tuple_get(void *_Nonnull tuple, int idx) {
    /// Return a borrowed reference
    void *v = PyTuple_GetItem(tuple, idx);
    return v;
}

VIM_INTEN void swiftvim_initialize() {
    Py_Initialize();
    if(!PyEval_ThreadsInitialized()) {
        PyEval_InitThreads();
    }

// FIXME: Move this to the Makefile or something 
#ifdef SPMVIM_LOADSTUB_RUNTIME
    // For unit tests, we fake out the vim module
    // to make the tests as pure as possible.
    // Assume that tests are running from the source root
    // We could do something better.
    char cwd[1024];
    if (getcwd(cwd, sizeof(cwd)) == NULL) {
        fprintf(stderr, "can't load testing directory");
        exit(1);
    }
    strcat(cwd, "/Tests/VimInterfaceTests/MockVimRuntime/");
    fprintf(stderr, "Adding test import path: %s \n", cwd);
    PyObject* sysPath = PySys_GetObject((char*)"path");
    PyObject* programName = SPyString_FromString(cwd);
    PyList_Append(sysPath, programName);
    Py_DECREF(programName);
#endif
}

VIM_INTEN void swiftvim_finalize() {
    Py_Finalize();
}

VIM_INTEN void *_Nullable swiftvim_get_error() {
    if (PyErr_Occurred()) {
        PyObject *type, *value, *traceback;
        PyErr_Fetch(&type, &value, &traceback);
        if (value) {
            return value;
        } else {
            return type;
        }
    }
    return NULL;
}

