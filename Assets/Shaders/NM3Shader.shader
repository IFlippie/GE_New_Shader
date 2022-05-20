Shader "Custom/NM3Shader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Normals("Normals", 2D) = "white" {}
        _Gloss("Gloss", Range(0,1)) = 1
        _Color("Color", Color) = (1,1,1,1)
    }
    SubShader
    {
        Tags { "RenderType"="Opaque"
                "LightMode"="ForwardBase"
        }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            #include "AutoLight.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float3 wPos : TEXCOORD4;
                float2 uv : TEXCOORD0;                
                float3 normal : TEXCOORD1;
                float3 tangent : TEXCOORD2;
                float3 bitangent : TEXCOORD3;
            };

            sampler2D _MainTex;
            sampler2D _Normals;
            float4 _MainTex_ST;
            float _Gloss;
            float4 _Color;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);

                o.normal = UnityObjectToWorldNormal(v.normal);
                o.tangent = UnityObjectToWorldDir(v.tangent.xyz);
                o.bitangent = cross(o.normal,o.tangent) * (v.tangent.w * unity_WorldTransformParams.w);

                o.wPos = mul(unity_ObjectToWorld, v.vertex);

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float3 tex = tex2D(_MainTex, i.uv);
                float3 texColor = tex * _Color.rgb;

                float3 tangentSpaceNormal = UnpackNormal(tex2D(_Normals, i.uv));

                float3x3 mtxTangToWorld = 
                {
                    i.tangent.x, i.bitangent.x, i.normal.x,
                    i.tangent.y, i.bitangent.y, i.normal.y,
                    i.tangent.z, i.bitangent.z, i.normal.z
                };

                float3 N = mul(mtxTangToWorld, tangentSpaceNormal);

                float3 L = normalize(UnityWorldSpaceLightDir(i.wPos));
                float attenuation = LIGHT_ATTENUATION(i);
                float3 lambert = saturate(dot(N, L));
                float3 diffuseLight = (lambert * attenuation) * _LightColor0.xyz;

                float3 V = normalize(_WorldSpaceCameraPos - i.wPos);
                float3 H = normalize(L + V);
                float3 specularLight = saturate(dot(H, N)) * (lambert > 0);
                float specularExponent = exp2(_Gloss * 11) + 2;
                specularLight = pow(specularLight, specularExponent) * _Gloss * attenuation;
                specularLight *= _LightColor0.xyz;

                return float4(diffuseLight * texColor + specularLight, 1);
            }
            ENDCG
        }
    }
}
