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
    }
    SubShader
    {
        Tags { "RenderType"="transparent" }

        Pass
        {
        Cull Off

        CGPROGRAM
        //These pragma's are ways of announcing that you have functions or variables with important information in them
        #pragma vertex vertexFunc
        #pragma fragment fragmentFunc
        #define PI 3.14159265359f

        float4 _Color;
        float _Strength;
        float _Speed;
        float2 _Direction;
        float _Wavelength;

        struct vertexInput
        {
            float4 vertex : POSITION;
        };

        struct vertexOutput
        {
            float4 pos : SV_POSITION;
            half3 worldNormal : TEXCOORD0;
        };

        vertexOutput vertexFunc(vertexInput IN)
        {
            vertexOutput o;

            //float4 worldPos = mul(unity_ObjectToWorld, IN.vertex);
            //float4 d = normalize(_Direction);

            //float4 displacement = (cos(worldPos.y) + cos(worldPos.x + (_Speed * _Time)));
            //worldPos.y = worldPos.y + (displacement * _Strength);

            //o.pos = mul(UNITY_MATRIX_VP, worldPos);

            float4 worldPos = mul(unity_ObjectToWorld, IN.vertex);

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

            //float3 tangent = normalize(float3(1 - k * _Strength * sin(f), k * _Strength * cos(f), 0));
            //float3 normal = float3(-tangent.y, tangent.x, 0);
            o.worldNormal = normal;
            //left off at multiple waves https://catlikecoding.com/unity/tutorials/flow/waves/ , and add water refraction and water foam to finish it
            return o;
        }

        float4 fragmentFunc(vertexOutput IN) : COLOR
        {
            return _Color;
        }

        ENDCG
           
        }
    }
}
