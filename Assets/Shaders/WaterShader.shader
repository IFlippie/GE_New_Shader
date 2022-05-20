Shader "Custom/WaterShader"
{
    //Properties are variables that will be shown in the Editor like publics in c#
    Properties
    {
        _Color("Color", Color) = (0,0,0,1)
        _Strength("Strength", Range(0,1)) = 0.5
        _Speed("Speed", Range(-200, 200)) = 100
        _Direction ("Direction (2D)", Vector) = (1,0,0,0)
        _Wavelength ("Wavelength", Float) = 10
        [NoScaleOffset] _NormalMap ("Normalmap ", 2D) = "" { }
        [NoScaleOffset] _ColorControl ("Fresnel", 2D) = "" { }
        _WaveScale ("Wave scale", Range (0.02,0.15)) = .07
    }
    SubShader
    {
        Tags { "RenderType"="transparent" "Queue" = "Transparent" }

        Pass
        {
        Cull Off

        CGPROGRAM
        //These pragma's are ways of announcing that you have functions or variables with important information in them
        #pragma vertex vertexFunc
        #pragma fragment fragmentFunc
        #define PI 3.14159265359f

        #include "UnityCG.cginc"

        float4 _Color;
        float _Strength;
        float _Speed;
        float2 _Direction;
        float _Wavelength;
        sampler2D _NormalMap;
        sampler2D _ColorControl;
        float _WaveScale;
        float4 _WaveOffset;

        struct vertexInput
        {
            float4 vertex : POSITION;
        };

        struct vertexOutput
        {
            float4 pos : SV_POSITION;
            half3 worldNormal : TEXCOORD0;
            float2 uv : TEXCOORD1;
            float3 viewDir : TEXCOORD2;
        };

        vertexOutput vertexFunc(vertexInput i)
        {
            vertexOutput o;

            //float4 worldPos = mul(unity_ObjectToWorld, i.vertex);
            //float4 d = normalize(_Direction);

            //float4 displacement = (cos(worldPos.y) + cos(worldPos.x + (_Speed * _Time)));
            //worldPos.y = worldPos.y + (displacement * _Strength);

            //o.pos = mul(UNITY_MATRIX_VP, worldPos);

            float4 worldPos = mul(unity_ObjectToWorld, i.vertex);

            float k = 2 * PI / _Wavelength;
            float2 d = normalize(_Direction);
            float f = k * (dot(d, worldPos.xz) - _Speed * _Time.y);
            float a = _Strength/k;

            worldPos.x += d.x * (a * cos(f));
            worldPos.y = a * sin(f);
            worldPos.z += d.y * (a * cos(f));

            o.pos = mul(UNITY_MATRIX_VP, worldPos);

            float3 tangent = float3( 1 - d.x * d.x * (_Strength * sin(f)), d.x * (_Strength * cos(f)), -d.x * d.y * (_Strength * sin(f)));
			float3 binormal = float3( -d.x * d.y * (_Strength * sin(f)), d.y * (_Strength * cos(f)), 1 - d.y * d.y * (_Strength * sin(f)));
			float3 normal = normalize(cross(binormal, tangent));

            float offset4 = _Speed * (_Time.x * _WaveScale);
            float4 offsetClamped = float4(fmod(offset4, 1),fmod(offset4, 1),fmod(offset4, 1),fmod(offset4, 1));
            _WaveOffset = offsetClamped;

            float4 temp;
            temp.xyzw = worldPos.xzxz * _WaveScale + _WaveOffset;
	        o.uv = temp.xyzw;
            o.viewDir.xzy = normalize( WorldSpaceViewDir(i.vertex) );

            o.worldNormal = normal;

            return o;
        }

        half4 fragmentFunc(vertexOutput i) : COLOR
        {
            half3 bump = UnpackNormal(tex2D( _NormalMap, i.uv )).rgb;
            
            //https://docs.unity3d.com/Packages/com.unity.shadergraph@6.9/manual/Fresnel-Effect-Node.html
            half fresnel = dot( i.viewDir, bump );
	        half4 water = tex2D( _ColorControl, float2(fresnel,fresnel) );
	
	        half4 col;
	        col.rgb = lerp( water.rgb, _Color.rgb, water.a );
	        col.a = _Color.a;
            return col;
        }

        ENDCG
           
        }
    }
}
