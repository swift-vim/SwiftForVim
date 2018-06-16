// Main vimscript methods

void *_Nullable swiftvim_command(const char *_Nonnull command);
void *_Nullable swiftvim_eval(const char *_Nonnull eval);

// Internally, the API uses reference counting
void *_Nullable swiftvim_decref(void *_Nullable value); 
void *_Nullable swiftvim_incref(void *_Nullable value);

// Value extraction
const char *_Nullable swiftvim_asstring(void *_Nullable value);
int swiftvim_asint(void *_Nullable value);

// List
int swiftvim_list_size(void *_Nonnull list);
void swiftvim_list_set(void *_Nonnull list, int i, void *_Nullable value);

void *_Nonnull swiftvim_list_get(void *_Nonnull list, int i);
void swiftvim_list_append(void *_Nonnull list, void *_Nullable value);


// Dict
void *_Nullable swiftvim_dict_get(void *_Nonnull dict, void *_Nullable key);
void swiftvim_dict_set(void *_Nonnull dict, void *_Nonnull key, void *_Nullable value); 

void *_Nullable swiftvim_dict_getstr(void *_Nonnull dict, const char *_Nonnull key);
void swiftvim_dict_setstr(void *_Nonnull dict, const char *_Nonnull key, void *_Nullable value); 

void *_Nonnull swiftvim_dict_values(void *_Nonnull dict);
void *_Nonnull swiftvim_dict_values(void *_Nonnull dict);
void *_Nonnull swiftvim_dict_keys(void *_Nonnull dict);
int swiftvim_dict_size(void *_Nonnull dict);

// Tuples
void *_Nullable swiftvim_tuple_get(void *_Nonnull tuple, int idx);


void *_Nullable swiftvim_call(const char *_Nonnull module, const char *_Nonnull method, const char *_Nullable str); 

void *_Nullable swiftvim_get_module(const char *_Nonnull module);
void *_Nullable swiftvim_get_attr(void *_Nonnull target, const char *_Nonnull attr);

void *_Nullable swiftvim_call_impl(void *func, void *_Nullable arg1, void *_Nullable arg2);

// Bootstrapping
// Note: These methods are only for testing purposes
void swiftvim_initialize();
void swiftvim_finalize();

