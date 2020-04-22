Shader "Translucency/Light_Translucency"
{
   Properties
    {
        _Specularity("Specularity", Float) = 100
        _Albedo("Albedo", Color) = (1,1,1,1)
        [HDR] _Scattering("Scattering Coefficient", Color) = (1,1,1,1)
        [HDR] _Absorption("Absorption Coefficient", Color) = (1,1,1,1)
        [KeywordEnum(None, Distance, Distance_Color,Ambient, Lambert ,Fresnel ,Transmitance)] _DEBUG ("DEBUG", Float) = 0
        _Mat1("Medium 1 Coefficient", Float) = 1
        _Mat2("Medium 2 Coefficient", Float) = 1.33
    }
    SubShader
    {
    
    CGINCLUDE
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
      ENDCG
      
         Pass
        {
        	Tags { "LightMode" = "ForwardBase" }

			CGPROGRAM
			#pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile _DEBUG_DISTANCE _DEBUG_DISTANCE_COLOR _DEBUG_AMBIENT _DEBUG_LAMBERT _DEBUG_FRESNEL _DEBUG_TRANSMITANCE _DEBUG_NONE
            #include "Assets/Lighting/TranslucentBTDF.cginc"
            
            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.normal = UnityObjectToWorldNormal(v.normal);
                return o;
            }
            
            float4 frag (v2f i) : SV_Target
            {
               #if _DEBUG_NONE || _DEBUG_AMBIENT
                return  ShadeSH9(float4(i.normal, 1)).xyzz;
               #endif
                return  0;
            }
            ENDCG
        }
       
       Pass
        {
            Tags { "LightMode" = "ForwardAdd" }
            Blend One One
            CGPROGRAM

            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile _DEBUG_DISTANCE _DEBUG_DISTANCE_COLOR _DEBUG_AMBIENT _DEBUG_LAMBERT _DEBUG_FRESNEL _DEBUG_TRANSMITANCE _DEBUG_NONE
            #include "Assets/Lighting/TranslucentBTDF.cginc"
          
            uniform sampler2D _LightDepth;
            uniform float4x4 _lightV;
            uniform float _Bias;
            uniform float _DiskWidth;
            uniform float _Albedo;
            
            //https://www.geeks3d.com/20100628/3d-programming-ready-to-use-64-sample-poisson-disc/
	        static float2 poissonDisk[16] =
	        {
	        	float2(0.2770745f, 0.6951455f),
	        	float2(0.1874257f, -0.02561589f),
	        	float2(-0.3381929f, 0.8713168f),
	        	float2(0.5867746f, 0.1087471f),
	        	float2(-0.3078699f, 0.188545f),
	        	float2(0.7993396f, 0.4595091f),
	        	float2(-0.09242552f, 0.5260149f),
	        	float2(0.3657553f, -0.5329605f),
	        	float2(-0.3829718f, -0.2476171f),
	        	float2(-0.01085108f, -0.6966301f),
	        	float2(0.8404155f, -0.3543923f),
	        	float2(-0.5186161f, -0.7624033f),
	        	float2(-0.8135794f, 0.2328489f),
	        	float2(-0.784665f, -0.2434929f),
	        	float2(0.9920505f, 0.0855163f),
	        	float2(-0.687256f, 0.6711345f)
	        };
	        
	           
	        float MultiSampleLightDepth(float2 uv,float d,int samples){
	            float accDepth = 0;
	            for(int i =0; i<samples;i++)
	            {
	            //TODO
	            // this is buggy, having the poisson disk be bigger the blacks(0 distance) to spread
	            // making the transmittance comparison receive a depth value close to depth from camera,
	            // cause we would be sending a depth value of 0 from the light point of view. and the substraction would result in a big positive number
	         
	               float2 uvJitter = uv + poissonDisk[i] *  (_DiskWidth)/_ScreenParams.xy; 
	                float depth = tex2D(_LightDepth,uvJitter).r ;
	                if(depth>0){
	                    accDepth += depth;
	                }
	                else{
	                samples--;
	                }
	            }
	            return accDepth/samples;
	        }

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.wpos = mul(UNITY_MATRIX_M,v.vertex);
                o.normal = UnityObjectToWorldNormal(v.normal);
                o.ppos = o.vertex;
                o.worldViewD = _WorldSpaceCameraPos.xyz -o.wpos.xyz ;
                float3 wposBiased = (o.wpos + _WorldSpaceLightPos0.xyz/_Bias ).xyz;
                o.lproyPos = mul(mul(UNITY_MATRIX_P,_lightV),o.wpos); // unity world to light does not work, so we reconstruct it :shrug:

                return o;
            }
            
            float4 frag (v2f i) : SV_Target
            {
                float3 N = normalize(i.normal);
                #if POINT || SPOT
                float3 L = normalize(i.wpos -_WorldSpaceLightPos0.xyz);
                #else
                float3 L = normalize(_WorldSpaceLightPos0.xyz);
                #endif  
                float3 V = normalize(-i.worldViewD);
 
                float distance =0;
                float3 uv = i.lproyPos.xyz/i.lproyPos.w;
                uv = (uv+1.0)/2.0;
              
                #if UNITY_UV_STARTS_AT_TOP
                    uv.y = 1-uv.y;   
                #endif

                float3 wposBiased = (i.wpos.xyz - _WorldSpaceLightPos0.xyz /_Bias );
                float visibleDepth =  length(mul(_lightV, i.wpos)); 
                //float lightDepth =   MultiSampleLightDepth(uv.xy, uv.z,8) ;
                //float lightDepth =   MultiSampleLightDepth(uv.xy, uv.z,16) ;
                float lightDepth =   MultiSampleLightDepth(uv.xy, uv.z,4) ;
                distance = (visibleDepth-lightDepth);
                  //most of this functions are stored in translucent.cginc
                float reflectance = rSchlick(V, N, _Mat1, _Mat2);
                
                #if _DEBUG_DISTANCE
                 return (lightDepth/40) * abs(dot(N,L));    
                #endif
                #if _DEBUG_DISTANCE_COLOR
                return float4(float2(lightDepth, visibleDepth),0,0)/40 ;    
                #endif
                #if _DEBUG_LAMBERT 
                return saturate(dot(N,L));//normalize(i.wpos -_WorldSpaceLightPos0.xyz).xyzz;//(dot(N,L)) *_Albedo;
                #endif
                #if _DEBUG_FRESNEL 
                return reflectance;
                #endif
                #if _DEBUG_TRANSMITANCE
                return  saturate(exp(-distance ));        
                #endif

                float3 reflectedRadiance = BRDF(N,L,V,1);
                float3 refractedRadiance = BTDF(N,L,V,distance,1);
             
                float3 finalColor = ((reflectance *reflectedRadiance) + (refractedRadiance*(1.0-reflectance)));
//                                                                            
                 return float4(finalColor.xyz,1);
                 //float4(pow(finalColor, 1./2.2),1.0); // Looks to bright with gamma... which probs means something is bad in the BTDF
                 //However I am not aiming for a full energy conserving thing.
                 
            }
            ENDCG
        }
        
      
    }
}


/*
 
        */
