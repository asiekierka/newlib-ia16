/* Macro to handle different function calling conventions.  */

#if defined __IA16_CALLCVT_STDCALL
# define RET_(n) ret $(n)
#else
# ifndef __IA16_CALLCVT_CDECL
#   warning "not sure which calling convention is in use; assuming cdecl"
# endif
# define RET_(n) ret
#endif
