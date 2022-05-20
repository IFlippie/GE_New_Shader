Shader "Custom/NormalMap"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        [NoScaleOffset] _NormalTex("Normals", 2D) = "bump" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque"
        "LightMode" = "ForwardBase" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float4 tangent : TANGENT;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 normal : NORMAL;
                float3 tbn[3] : TEXCOORD1;
            };

            sampler2D _MainTex;
            sampler2D _NormalTex;
            float4 _MainTex_ST;
            float4 _NormalTex_ST;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                //o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.uv = TRANSFORM_TEX(v.uv, _NormalTex);

                float3 normal = UnityObjectToWorldNormal(v.normal);
                float3 tangent = UnityObjectToWorldNormal(v.tangent);
                float3 bitangent = cross(tangent, normal);

                o.tbn[0] = tangent;
                o.tbn[1] = bitangent;
                o.tbn[2] = normal;

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 col = tex2D(_MainTex, i.uv);

                float3 tangentNormal = tex2D(_NormalTex, i.uv) * 2 - 1;
				float3 surfaceNormal = i.tbn[2];
				float3 worldNormal = float3(i.tbn[0] * tangentNormal.r + i.tbn[1] * tangentNormal.g + i.tbn[2] * tangentNormal.b);

                //float3 bumpp = dot(worldNormal, _WorldSpaceLightPos0);
               // float4 result = (col * bumpp, 1);

				return dot(worldNormal, _WorldSpaceLightPos0); //col
            }

            ENDCG
        }
    }
}
