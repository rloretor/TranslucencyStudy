// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Unlit/FluidInstantiation"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
    
        Tags { "RenderType"="Transparent"  "Queue" = "Transparent" }

        Pass 
        {
            Name "BackFace"
            ColorMask RGB
            CGPROGRAM
            
                #pragma vertex vert
                #pragma fragment frag
                
                #pragma target 4.5
                #include "UnityCG.cginc"
    
                struct appdata
                {
                    float4 vertex : POSITION;
                };
    
                struct v2f
                {
                    float4 vertex : SV_POSITION;
                    float4 ProjectionSpace: TEXCOORD0;
       
                };
    
                StructuredBuffer<float4> positionBuffer;    
                
    
                v2f vert (appdata v)
                {
                    v2f o;
                    o.vertex = UnityObjectToClipPos(v.vertex);
                    o.ProjectionSpace = UnityObjectToClipPos(v.vertex);
                    return o;
                }
  
                fixed4 frag (v2f i) : SV_Target
                {
                    float AR = _ScreenParams.x/_ScreenParams.y;
                    float2 ClipPos = i.ProjectionSpace.xy/i.ProjectionSpace.w;
                    ClipPos.x *= AR;
                    if(length(ClipPos)<0.5){
                    discard;
                    }
                    return fixed4(length(ClipPos),0,0,1);
                }

            ENDCG
        }
    }
}
