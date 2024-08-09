Shader "Custom/ShadowMap"
{
    Properties
    {
        // _BiasNormal("Bias Normal", Range(0, 0.02)) = 0.01
        // _BiasConstant("Bias Constant", Range(0, 0.02)) = 0.01
    }
    CGINCLUDE
    #include "UnityCG.cginc"
    #include "GlobalConfig.cginc"
    ENDCG
    SubShader
    {
        Tags { "RenderType"="Opaque" }

        Pass
        {
            Cull off
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            uniform float3 light;
            uniform float normalBias;
            uniform float g_BiasConstant;
            uniform float g_BiasNormal;

            struct v2f 
            {
                float4 pos: SV_POSITION;
                float4 pos_W: TEXCOORD0;
                float3 normal_W: TEXCOORD1;
                // float2 depth: TEXCOORD0;
            };

            v2f vert(appdata_base v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.pos_W = mul(unity_ObjectToWorld, v.vertex);
                o.normal_W = normalize(mul(v.normal, (float3x3)unity_WorldToObject));
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                float depth = i.pos.z / i.pos.w;
#if defined (UNITY_REVERSED_Z)
#if defined (NDC_DEPTH_NEGATIVE_ONE_TO_ONE)
				depth = depth * 0.5 + 0.5;
#endif
                depth = 1.0 - depth;
#endif
                // add bias
                float3 V = normalize(light - i.pos_W.xyz);
                float weight = 1 - dot(V, i.normal_W);
                depth += g_BiasConstant + weight * g_BiasNormal;
                return fixed4(depth, 0, 0, 1.0f);
            }
            ENDCG
        }

    }
}
