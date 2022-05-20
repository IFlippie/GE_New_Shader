Shader "Custom/TransparentWater"
{
    Properties
    {
        _Color ("Tint", Color) = (0, 0, 0, 1)
		_MainTex ("Texture", 2D) = "white" {}
        [NoScaleOffset] _FlowMap ("Flow (RG)", 2D) = "black" {}
        _FlowSpeed ("Flow Speed", float) = 0.05
    }
    SubShader
    {
        Tags{ "RenderType"="Transparent" "Queue"="Transparent"}

		Blend SrcAlpha OneMinusSrcAlpha
		ZWrite off

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            //#pragma target 3.0
            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float4 color    : COLOR;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                fixed4 color    : COLOR;
            };

            sampler2D _MainTex;
            sampler2D _FlowMap;
            float4 _MainTex_ST;
            fixed4 _Color;
            float3 flowVector;
            //float2 flowVector;
            float _FlowSpeed;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.color = v.color * _Color;
                //flowVector = tex2Dlod(_FlowMap, o.uv).rg * 2 - 1;

                o.uv = o.uv + _Time.x;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                flowVector = tex2D(_FlowMap, i.uv) * 2 - 1;
                flowVector *= _FlowSpeed;
                //fixed4 col = tex2D(_MainTex, i.uv) * _Color;

                float phase0 = frac(_Time[1] * 0.5f + 0.5f);
                float phase1 = frac(_Time[1] * 0.5f + 1.0f);

                half3 tex0 = tex2D(_MainTex, i.uv + flowVector.xy * phase0);
                half3 tex1 = tex2D(_MainTex, i.uv + flowVector.xy * phase1);

                float flowLerp = abs((0.5f - phase0) / 0.5f);
                half3 finalColor = lerp(tex0, tex1, flowLerp);

                fixed4 col = float4(finalColor, 1.0f) * i.color;
                col.rgb *= col.a;

                //col.rgb *= col.a;
                
                return col;
            }
            ENDCG
        }
    }
}
