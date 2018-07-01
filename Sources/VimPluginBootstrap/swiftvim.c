// Core Python -> Swift bootstrap
// The vim plugin is expected to call swiftvim_load when
// it's time to initialize the plugin
#include <Python.h>
#include <unistd.h>

// Namespace the plugin names
#define _MAKE_FN_NAME_P_2(y, x) y ## x
#define _MAKE_FN_NAME_P(y, x) _MAKE_FN_NAME_P_2(y, x)
#define PLUGIN_FUNC(s, p) _MAKE_FN_NAME_P(s, p)

#define _PLUGIN_NAME_STR_2(s) #s
#define _PLUGIN_NAME_STR(s) _PLUGIN_NAME_STR_2(s)
#define PLUGIN_NAME_STR _PLUGIN_NAME_STR(VIM_PLUGIN_NAME)

// Symbols within this program are exported
// Mantra:
// The symbols exported are the ones necessary.
// Any exported symbols *MUST* be namespaced.
#define VIM_EXTERN extern __attribute__((visibility("default")))


// Plugin load is called to bootstrap the plugin in vim
// These methods are defined within the user provided library
// The VimInteface doesn't actually define these.
extern int PLUGIN_FUNC(VIM_PLUGIN_NAME, _plugin_load)(const char *)  __attribute__((weak));
extern const char *PLUGIN_FUNC(VIM_PLUGIN_NAME, _plugin_runloop_callback)(void)  __attribute__((weak));
extern const char *PLUGIN_FUNC(VIM_PLUGIN_NAME, _plugin_invoke)(void*)  __attribute__((weak));

static PyObject *swiftvimError;

// Python methods
static PyObject *PLUGIN_FUNC(VIM_PLUGIN_NAME, _load)(PyObject *self, PyObject *args);
static PyObject *PLUGIN_FUNC(VIM_PLUGIN_NAME, _invoke)(PyObject *self, PyObject *args);
static PyObject *PLUGIN_FUNC(VIM_PLUGIN_NAME, _runloop_callback)(PyObject *self, PyObject *args);

static PyMethodDef swiftvimMethods[] = {
    {"load",  PLUGIN_FUNC(VIM_PLUGIN_NAME, _load), METH_VARARGS,
     "Load the plugin."},

    {"invoke",  PLUGIN_FUNC(VIM_PLUGIN_NAME, _invoke), METH_VARARGS,
     "Invoke a user callback"},

    {"runloop_callback",  PLUGIN_FUNC(VIM_PLUGIN_NAME, _runloop_callback), METH_VARARGS,
     "RunLoop callback"},

    {NULL, NULL, 0, NULL}        /* Sentinel */
};

#if PY_MAJOR_VERSION == 3

static struct PyModuleDef swiftvimmodule = {
    PyModuleDef_HEAD_INIT,
    PLUGIN_NAME_STR, /* name of module */
    NULL, /* module documentation, may be NULL */
    -1, /* size of per-interpreter state of the module,
        or -1 if the module keeps state in global variables. */
    swiftvimMethods
};

VIM_EXTERN PyMODINIT_FUNC PLUGIN_FUNC(PyInit_, VIM_PLUGIN_NAME)(void) {
    PyObject *m;

    m = PyModule_Create(&swiftvimmodule);
    if (m == NULL)
        return NULL;

    swiftvimError = PyErr_NewException("swiftvim.error", NULL, NULL);
    Py_INCREF(swiftvimError);
    PyModule_AddObject(m, "error", swiftvimError);
    return m;
}

#else 

VIM_EXTERN PyMODINIT_FUNC PLUGIN_FUNC(init, VIM_PLUGIN_NAME)(void) {
    PyObject *m;

    m = Py_InitModule(PLUGIN_NAME_STR, swiftvimMethods);
    if (m == NULL)
        return;

    swiftvimError = PyErr_NewException("swiftvim.error", NULL, NULL);
    Py_INCREF(swiftvimError);
    PyModule_AddObject(m, "error", swiftvimError);
}
#endif

// Mark - Method Implementations

static int calledPluginInit = 0;

static PyObject *PLUGIN_FUNC(VIM_PLUGIN_NAME, _load)(PyObject *self, PyObject *args)
{
    int status = 1;
    if (calledPluginInit == 0) {
        status = PLUGIN_FUNC(VIM_PLUGIN_NAME, _plugin_load)("load");
        calledPluginInit = 1;
    } else {
        fprintf(stderr, "warning: called swiftvim.plugin_load more than once");
    }
    return Py_BuildValue("i", status);
}

static PyObject *PLUGIN_FUNC(VIM_PLUGIN_NAME, _runloop_callback)(PyObject *self, PyObject *args)
{
    PLUGIN_FUNC(VIM_PLUGIN_NAME, _plugin_runloop_callback)();
    return Py_BuildValue("i", 0);
}

static PyObject *PLUGIN_FUNC(VIM_PLUGIN_NAME, _invoke)(PyObject *self, PyObject *args)
{
    void *result = (void *)PLUGIN_FUNC(VIM_PLUGIN_NAME, _plugin_invoke)(args);
    return Py_BuildValue("s", result);
}


