Shader "Translucency/Light_Translucency"
{
   Properties
    {
        _Specularity("Specularity", Float) = 100
        [HDR] _Scattering("Scattering Coefficient", Color) = (1,1,1,1)
        [HDR] _Absorption("Absorption Coefficient", Color) = (1,1,1,1)

        _Mat1("Mat1", Float) = 1
        _Mat2("Mat2", Float) = 1.33
    }
    SubShader
    {
        Tags { "LightMode" = "ForwardBase" }

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Assets/Lighting/TranslucentBTDF.cginc"
            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal:NORMAL;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float3 worldViewD : TEXCOORD0;
                float4 wpos :TEXCOORD1;
                float4 lproyPos:TEXCOORD2;
                float3 normal:TEXCOORD3;
                float4 ppos:TEXCOORD4;
            };

            sampler2D _LightDepth;
            float4x4 _lightV;
            

           
            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.wpos = mul(UNITY_MATRIX_M,v.vertex);
                o.normal = UnityObjectToWorldNormal(v.normal);
                o.ppos = o.vertex;
                o.worldViewD = _WorldSpaceCameraPos.xyz -o.wpos.xyz ;
                o.lproyPos = mul(mul(UNITY_MATRIX_P,_lightV),o.wpos);

                return o;
            }

            float4 frag (v2f i) : SV_Target
            {
                float3 N = normalize(i.normal);
                float3 L = normalize(_WorldSpaceLightPos0.xyz);
                float3 V = normalize(-i.worldViewD);
 
                float distance =0;
                float2 uv = i.lproyPos.xy/i.lproyPos.w;
                uv = (uv+1.0)/2.0;
              
                #if UNITY_UV_STARTS_AT_TOP
                    uv.y = 1-uv.y;   
                #endif
                 float bias = 0.3; 

                float visibleDepth =  length(mul(_lightV, i.wpos  ).xyz) ; 
                float lightDepth = tex2D(_LightDepth,uv).r + bias;
                distance = (visibleDepth-lightDepth);
                                       
                //most of this functions are stored in translucent.cginc
                float reflectance = rSchlick(V, N, _Mat1, _Mat2);
              
                float3 reflectedRadiance = BRDF(N,L,V);
                float3 refractedRadiance = BTDF(N,L,V,distance);
             
                float3 finalColor = ((reflectance *reflectedRadiance) + (refractedRadiance*(1.0-reflectance)))/4*acos(-1);
//                                                                Is sphere normalization even needed         ^^^^^^^^^^  

                //return distance/10;
                 return float4(pow(finalColor, 1./2.2),1.0);
            }
            ENDCG
        }
    }
}

