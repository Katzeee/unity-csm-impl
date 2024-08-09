#ifndef _GLOBAL_CONFIG_CGINC_
#define _GLOBAL_CONFIG_CGINC_

#if defined(SHADER_API_GLCORE) || defined(SHADER_API_GLES) || defined(SHADER_API_GLES3)
    #define NDC_DEPTH_NEGATIVE_ONE_TO_ONE 1
#endif

#endif