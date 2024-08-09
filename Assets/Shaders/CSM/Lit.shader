Shader "Custom/Lit"
{
    Properties{
        _Diffuse("Diffuse Color", Color) = (1, 1, 1, 1) 
    }

    CGINCLUDE
    #include "UnityCG.cginc"
    ENDCG
    SubShader {
        Tags { "RenderType"="Opaque" }
        Pass {

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            uniform int _gShadowMapCount;
			uniform sampler2D _gShadowMapTexture0;
			uniform sampler2D _gShadowMapTexture1;
			uniform sampler2D _gShadowMapTexture2;
			uniform sampler2D _gShadowMapTexture3;
            uniform float4x4 _gWorldToLightClipMat[8];

            uniform float3 light;

            fixed4 _Diffuse; 
            float textureSize = 1024.0f;

            struct v2f 
            {
                float4 pos: SV_POSITION;
                float4 pos_W: TEXCOORD0;
                float3 normal_W: TEXCOORD1;
            };

            v2f vert(appdata_base v)
            { 
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.pos_W = mul(unity_ObjectToWorld, v.vertex);
// fixed normalDir = normalize(mul(v.normal, (float3x3)unity_WorldToObject));
                o.normal_W = normalize(mul(v.normal, (float3x3)unity_WorldToObject));
                return o;
            }

            float PCF(sampler2D shadowMap, float3 pos_L) 
            {
                float shadow = 0.0f;
                int kernel = 2;
                for (int i = -kernel; i <= kernel; i++)
                {
                    for (int j = -kernel; j <= kernel; j++)
                    {
                        float depth = tex2D(shadowMap, pos_L.xy + float2(i / 1024.0f, j / 1024.0f)).x; 
                        shadow += pos_L.z > depth ? 0.0f : 1.0f;
                    }
                }

                return shadow / 25.0f;
            }

            float CaculateShadow(float4 pos_W)
            {
                float4 pos_L;
                float shadow[8];
                int in_shadow[8];
                for (int j = 0; j < _gShadowMapCount ; j++)
                {
                    in_shadow[j] = 0;
                    shadow[j] = 1;
                    pos_L = mul(_gWorldToLightClipMat[j], pos_W);
                    pos_L = pos_L / pos_L.w; // to light ndc
                    pos_L.xyz = pos_L.xyz * 0.5f + 0.5f; // xy = uv, z = depth
                    if (pos_L.x >= 0 && pos_L.x <= 1 && 
                        pos_L.y >= 0 && pos_L.y <= 1 && 
                        pos_L.z >= 0 && pos_L.z <= 1 - 0.01) // in cur split
                    {
                        switch (j) 
                        {
                            case 0:
                                // if (pos_L.z > tex2D(_gShadowMapTexture0, pos_L.xy).x) 
                                // {
                                    shadow[j] = PCF(_gShadowMapTexture0, pos_L);
                                    // shadow[j] = 0.1;
                                    // in_shadow[j] = 1;
                                // }
                                break;
                            case 1:
                                    shadow[j] = PCF(_gShadowMapTexture1, pos_L);
                                break;
                            case 2:
                                    shadow[j] = PCF(_gShadowMapTexture2, pos_L);
                                break;
                            case 3:
                                    shadow[j] = PCF(_gShadowMapTexture3, pos_L);
                                break;
                        }
                    }
                    
                }
                for (int j = 0; j < _gShadowMapCount; j++)
                {
                    if (shadow[j] < 1) 
                    {
                        return shadow[j];
                    }
                }
                return 1;
            }


            fixed4 frag(v2f i) : SV_Target 
            { 
                fixed4 ambient = float4(UNITY_LIGHTMODEL_AMBIENT.rgb, 1.0);
                fixed3 lightDir = normalize(_WorldSpaceLightPos0.xyz);
                fixed4 color = float4(1.0, 1.0, 1.0, 1.0);
                color.xyz = _Diffuse.xyz * max(0, dot(i.normal_W, lightDir));

                float shadow = CaculateShadow(i.pos_W);

                return color * shadow;
            }
            ENDCG
        }
    }
    Fallback "Diffuse"
}