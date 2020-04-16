
Shader "CRP/Light_Depth"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {

        Tags { "RenderType"="Opaque" "LightMode" = "ForwardBase" }
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
                        //uniform float4x4 unity_WorldToLight;

             v2f vert (appdata v)
            {
                v2f o;
                o.wpos = mul(UNITY_MATRIX_M,v.vertex);
                o.N = UnityObjectToWorldNormal(v.N);
                o.vertex  = mul(mul(UNITY_MATRIX_P,_lightV), o.wpos );
                return o;
            }
            
            fixed4 frag (v2f i) : SV_Target
            {
                return length(mul(_lightV, float4(i.wpos.xyz + i.N*0.05,1 )).xyz);
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
