Shader "CRP/View_depth" {
    SubShader {
        CGINCLUDE
            #include "UnityCG.cginc"
            struct appdata
            {
                float4 vertex : POSITION;
                float4 uv : TEXCOORD0;
            };
    
            struct v2f
            {
                float4 vertex : SV_POSITION;
                float4 vpos :TEXCOORD1;
            };
             
            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.vpos = mul(UNITY_MATRIX_MV,v.vertex);
                return o;
            }
            float2 frag (v2f i) : SV_Target
            {
               return  i.vpos.z;
            }

        ENDCG

        Pass {
             ZWrite On
             ZTest LEqual
             Cull Back
             ColorMask 0
             CGPROGRAM
                #pragma vertex vert
                #pragma fragment frag0
                #include "UnityCG.cginc"   
              
                float frag0 (v2f i) : SV_Target
                {
                    return 0;
                }
             ENDCG
            }
            
         Pass {
            ZWrite On
            Blend Off
            Cull Front
            ZTest GEqual        
            ColorMask R
            CGPROGRAM
                #pragma vertex vert
                #pragma fragment frag
                #include "UnityCG.cginc"
            ENDCG
            }  
        
        Pass 
        {
           ZTest LEqual
           ZWrite On
           Cull back
           ColorMask G
           CGPROGRAM
                #pragma vertex vert
                #pragma fragment frag
                #include "UnityCG.cginc"
               
           ENDCG
       }
    }
}