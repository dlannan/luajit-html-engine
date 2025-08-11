local ffi  = require( "ffi" )

local duktape_filename = _G.DUKTAPE_DLL or "duktape_dll"
local libs = ffi_duktape or {
   OSX     = { x64 = duktape_filename..".so" },
   Windows = { x64 = duktape_filename..".dll" },
   Linux   = { x64 = duktape_filename..".so", arm = duktape_filename..".so" },
   BSD     = { x64 = duktape_filename..".so" },
   POSIX   = { x64 = duktape_filename..".so" },
   Other   = { x64 = duktape_filename..".so" },
}

local lib  = ffi_duktape or libs[ ffi.os ][ ffi.arch ]
local duktape   = ffi.load( lib )

-- load lcpp (ffi.cdef wrapper turned on per default)
-- local lcpp = require("tools.lcpp")

-- just use LuaJIT ffi and lcpp together
ffi.cdef([[
/* A few types are assumed to always exist. */
typedef size_t duk_size_t;
typedef ptrdiff_t duk_ptrdiff_t;

typedef struct duk_hthread duk_context;
typedef int duk_int_t;
typedef int duk_ret_t;
typedef unsigned int duk_uint_t;
typedef bool duk_bool_t;
typedef double duk_double_t;

typedef duk_int_t duk_codepoint_t;
typedef duk_uint_t duk_ucodepoint_t;
typedef duk_int_t duk_idx_t;

/*
 *  Public API specific typedefs
 *
 *  Many types are wrapped by Duktape for portability to rare platforms
 *  where e.g. 'int' is a 16-bit type.  See practical typing discussion
 *  in Duktape web documentation.
 */

struct duk_thread_state;
struct duk_memory_functions;
struct duk_function_list_entry;
struct duk_number_list_entry;
struct duk_time_components;

/* duk_context is now defined in duk_config.h because it may also be
 * referenced there by prototypes.
 */
typedef struct duk_thread_state duk_thread_state;
typedef struct duk_memory_functions duk_memory_functions;
typedef struct duk_function_list_entry duk_function_list_entry;
typedef struct duk_number_list_entry duk_number_list_entry;
typedef struct duk_time_components duk_time_components;

typedef duk_ret_t (*duk_c_function)(duk_context *ctx);
typedef void *(*duk_alloc_function) (void *udata, duk_size_t size);
typedef void *(*duk_realloc_function) (void *udata, void *ptr, duk_size_t size);
typedef void (*duk_free_function) (void *udata, void *ptr);
typedef void (*duk_fatal_function) (void *udata, const char *msg);
typedef void (*duk_decode_char_function) (void *udata, duk_codepoint_t codepoint);
typedef duk_codepoint_t (*duk_map_char_function) (void *udata, duk_codepoint_t codepoint);
typedef duk_ret_t (*duk_safe_call_function) (duk_context *ctx, void *udata);
typedef duk_size_t (*duk_debug_read_function) (void *udata, char *buffer, duk_size_t length);
typedef duk_size_t (*duk_debug_write_function) (void *udata, const char *buffer, duk_size_t length);
typedef duk_size_t (*duk_debug_peek_function) (void *udata);
typedef void (*duk_debug_read_flush_function) (void *udata);
typedef void (*duk_debug_write_flush_function) (void *udata);
typedef duk_idx_t (*duk_debug_request_function) (duk_context *ctx, void *udata, duk_idx_t nvalues);
typedef void (*duk_debug_detached_function) (duk_context *ctx, void *udata);

duk_context *duk_create_heap(duk_alloc_function alloc_func,
                             duk_realloc_function realloc_func,
                             duk_free_function free_func,
                             void *heap_udata,
                             duk_fatal_function fatal_handler);
void duk_destroy_heap(duk_context *ctx);

duk_idx_t duk_push_c_function(duk_context *ctx, duk_c_function func, duk_idx_t nargs);

duk_bool_t duk_put_global_string(duk_context *ctx, const char *key);
duk_bool_t duk_get_global_string(duk_context *ctx, const char *key);

duk_int_t duk_eval_raw(duk_context *ctx, const char *src_buffer, duk_size_t src_length, duk_uint_t flags);
duk_int_t duk_compile_raw(duk_context *ctx, const char *src_buffer, duk_size_t src_length, duk_uint_t flags);

void duk_call(duk_context *ctx, duk_idx_t nargs);
duk_int_t duk_safe_call(duk_context *ctx, duk_safe_call_function func, void *udata, duk_idx_t nargs, duk_idx_t nrets);

void duk_pop(duk_context *ctx);
void duk_pop_2(duk_context *ctx);

duk_idx_t duk_get_top(duk_context *ctx);
duk_idx_t duk_get_top_index(duk_context *ctx);
void duk_gc(duk_context *ctx, duk_uint_t flags);

void duk_push_null(duk_context *ctx);
duk_int_t duk_get_type(duk_context *ctx, duk_idx_t idx);

duk_double_t duk_random(duk_context *ctx);

duk_int_t duk_get_int(duk_context *ctx, duk_idx_t idx);
const char *duk_get_string(duk_context *ctx, duk_idx_t idx);
duk_int_t duk_get_uint(duk_context *ctx, duk_idx_t idx);
duk_int_t duk_to_int(duk_context *ctx, duk_int_t index);

duk_bool_t duk_get_boolean(duk_context *ctx, duk_idx_t idx);
duk_double_t duk_get_number(duk_context *ctx, duk_idx_t idx);

duk_double_t duk_to_number(duk_context *ctx, duk_idx_t idx);
duk_int_t duk_to_int(duk_context *ctx, duk_idx_t idx);
duk_bool_t duk_to_boolean(duk_context *ctx, duk_idx_t idx);
duk_uint_t duk_to_uint(duk_context *ctx, duk_idx_t idx);

duk_double_t duk_require_number(duk_context *ctx, duk_idx_t idx);
duk_int_t duk_require_int(duk_context *ctx, duk_idx_t idx);
duk_uint_t duk_require_uint(duk_context *ctx, duk_idx_t idx);
duk_bool_t duk_require_boolean(duk_context *ctx, duk_idx_t idx);

const char *duk_to_string(duk_context *ctx, duk_idx_t idx);
const char *duk_safe_to_lstring(duk_context *ctx, duk_idx_t idx, duk_size_t *out_len);
const char *duk_push_string(duk_context *ctx, const char *str);
const char *duk_push_lstring(duk_context *ctx, const char *str, duk_size_t len);
const char *duk_require_lstring(duk_context *ctx, duk_idx_t idx, duk_size_t *out_len);
void duk_push_int(duk_context *ctx, duk_int_t val);

duk_bool_t duk_get_prop_string(duk_context *ctx, duk_idx_t obj_idx, const char *key);

void duk_push_pointer(duk_context *ctx, void *p);
void *duk_get_pointer(duk_context *ctx, duk_idx_t idx);

void duk_inspect_callstack_entry(duk_context *ctx, duk_int_t level);
const char *duk_to_stacktrace(duk_context *ctx, duk_idx_t idx);

void duk_json_decode(duk_context *ctx, duk_idx_t idx);
const char *duk_json_encode(duk_context *ctx, duk_idx_t idx);

void duk_base64_decode(duk_context *ctx, duk_idx_t idx);
const char *duk_base64_encode(duk_context *ctx, duk_idx_t idx);

enum {
   DUK_COMPILE_EVAL = 8,
   DUK_COMPILE_STRICT = 32,
   DUK_COMPILE_SAFE = 128,
   DUK_COMPILE_NOSOURCE = 512,
   DUK_COMPILE_STRLEN = 1024,
   DUK_COMPILE_NOFILENAME = 2048
};

]])

return duktape