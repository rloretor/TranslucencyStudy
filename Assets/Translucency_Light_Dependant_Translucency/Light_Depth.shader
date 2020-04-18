Shader "CRP/Light_Depth"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        CGINCLUDE

        #include "UnityCG.cginc"
        struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float4 N : NORMAL;
            };
            struct v2f
            {
                float4 vertex : SV_POSITION;
                float4 wpos : TEXCOORD0;
                float3 N : TEXCOORD1;

            };
            float4x4 _lightVP;
            float4x4 _lightV;

             v2f vert (appdata v)
            {
                v2f o;
                o.wpos = mul(unity_ObjectToWorld,v.vertex);
                o.N = UnityObjectToWorldNormal(v.N);
                o.vertex  = mul(mul(UNITY_MATRIX_P,_lightV), o.wpos );
                return o;
            }
            
            float4 frag (v2f i) : SV_Target
            {
                float d =length(mul(_lightV, i.wpos).xyz);
                return d;
            }
        ENDCG

        Pass 
        {
            ColorMask R
            Tags { "RenderType"="Opaque" "LightMode" = "ForwardBase" }        

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            
            ENDCG
        }
        

    }
}
