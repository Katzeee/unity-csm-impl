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
            uniform float _gZNear[8];
            uniform float _gZFar[8];

            // uniform float3 light;

            fixed4 _Diffuse; 
            float textureSize = 1024.0f;
            float blend_threshold = 0.8f;

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
                o.normal_W = normalize(mul(v.normal, (float3x3)unity_WorldToObject));
                return o;
            }

            float PCF(int kernel, sampler2D shadowMap, float3 pos_L) 
            {
                float shadow = 0.0f;
                for (int i = -kernel; i <= kernel; i++)
                {
                    for (int j = -kernel; j <= kernel; j++)
                    {
                        float depth = tex2D(shadowMap, pos_L.xy + float2(i / 1024.0f, j / 1024.0f)).x; 
                        shadow += pos_L.z > depth ? 0.0f : 1.0f;
                    }
                }
                float texture_area = kernel * 2.0f + 1.0f;
                return shadow / texture_area / texture_area;
            }
            
            float CalculateBlend(float4 pos_L)
            {
                float2 one_minus_pos_L = float2(1 - pos_L.x, 1 - pos_L.y);
                float min1 = min(pos_L.x, pos_L.y);
                float min2 = min(one_minus_pos_L.x, one_minus_pos_L.y);
                float weight = min(min1, min2) / 0.5f;
                return weight;
            }

            int CalculateSplit(float4 pos_W, inout float4 pos_L, inout float4 next_split_pos_L)
            {
                for (int i = 0; i < _gShadowMapCount ; i++)
                {
                    pos_L = mul(_gWorldToLightClipMat[i], pos_W);
                    pos_L = pos_L / pos_L.w; // to light ndc
                    pos_L.xyz = pos_L.xyz * 0.5f + 0.5f; // xy = uv, z = depth
                    if (pos_L.x >= 0 && pos_L.x <= 1 && 
                        pos_L.y >= 0 && pos_L.y <= 1 && 
                        pos_L.z >= 0 && pos_L.z <= 1 - 0.01) // in cur split
                    {
                        if (i != _gShadowMapCount)
                        {
                            next_split_pos_L = mul(_gWorldToLightClipMat[i + 1], pos_W);
                            next_split_pos_L = next_split_pos_L / next_split_pos_L.w; // to light ndc
                            next_split_pos_L.xyz = next_split_pos_L.xyz * 0.5f + 0.5f; // xy = uv, z = depth
                        }
                        return i;
                    }
                    
                }
                return _gShadowMapCount;
            }

            float CalculateShadow(float4 pos_W)
            {
                float4 pos_L;
                float4 next_split_pos_L;
                int split = CalculateSplit(pos_W, pos_L, next_split_pos_L);
                half shadow = 1.0f;
                half next_shadow = 1.0f;
                switch (split)
                {
                    case 0:
                        shadow = PCF(1, _gShadowMapTexture0, pos_L);
                        next_shadow = PCF(1, _gShadowMapTexture1, next_split_pos_L);
                        break;
                    case 1:
                        shadow = PCF(1, _gShadowMapTexture1, pos_L);
                        next_shadow = PCF(1, _gShadowMapTexture2, next_split_pos_L);
                        break;
                    case 2:
                        shadow = PCF(1, _gShadowMapTexture2, pos_L);
                        next_shadow = PCF(1, _gShadowMapTexture3, next_split_pos_L);
                        break;
                    case 3:
                        shadow = PCF(1, _gShadowMapTexture3, pos_L);
                        break;
                }
                // blend
                half weight = 0.0f;
                if (split < _gShadowMapCount)
                {
                    weight = CalculateBlend(pos_L);
                }

                return lerp(next_shadow, shadow, weight);
            }

            fixed4 frag(v2f i) : SV_Target 
            { 
                fixed4 ambient = float4(UNITY_LIGHTMODEL_AMBIENT.rgb, 1.0);
                fixed3 lightDir = normalize(_WorldSpaceLightPos0.xyz);
                fixed4 diffuse = float4(1.0, 1.0, 1.0, 1.0);
                diffuse.xyz = _Diffuse.xyz * max(0, dot(i.normal_W, lightDir));

                float shadow = CalculateShadow(i.pos_W);

                return ambient + diffuse * shadow;
            }
            ENDCG
        }
    }
    Fallback "Diffuse"
}