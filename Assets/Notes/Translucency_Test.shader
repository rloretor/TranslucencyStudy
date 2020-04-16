Shader "Unlit/Translucency_1"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Specularity("Specularity", Float) = 100
        _Extintion("Density", Color) = (1,1,1,1)
        _Mat1("Mat1", Float) = 1
        _Mat2("Mat2", Float) = 1.33
    }
    SubShader
    {
        Tags {"LightMode" = "ForwardBase" "RenderType"="Transparent" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            #include "UnityLightingCommon.cginc"
            
            #define z(uv)  tex2D(_DepthDifference,uv)
            #define e float3(1/_ScreenParams.xy  ,0)
            

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal:NORMAL;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float3 worldViewD : TEXCOORD1;
                float4 pPos : TEXCOORD2;
                float3 normal:NORMAL;
                float4 vertex : SV_POSITION;
            };

            sampler2D _DepthDifference;
            sampler2D _Color;
            float _Specularity;
            float3 _Extintion;
            float _Mat1;
            float _Mat2;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.pPos = o.vertex;
                o.uv = v.uv;
                float3 wpos =  mul(unity_ObjectToWorld , v.vertex).xyz;
                o.worldViewD = _WorldSpaceCameraPos.xyz -wpos.xyz ;
                o.normal  = UnityObjectToWorldNormal(v.normal);
                return o;
            }
            
             float3 GetSky(float3 worldViewDir,float3 N,int Lod){
                float3 R = reflect(worldViewDir, N);
                float4 skyData = UNITY_SAMPLE_TEXCUBE_LOD(unity_SpecCube0, R,Lod);
                return  DecodeHDR (skyData, unity_SpecCube0_HDR).xyz;
            }
            
            float rSchlick(float3 incident, float3 normal, float n1, float n2)
            {
                float r0 = (n1 - n2) / (n1 + n2);
                r0 *= r0;
                float cos  = 1.0 + dot(normal, incident);
                return saturate(r0 + (1.0 - r0) * pow(cos,5.0));
            }     

            fixed4 frag (v2f i) : SV_Target
            {
                float3 N = normalize(i.normal);
                float3 L = normalize(_WorldSpaceLightPos0.xyz);
                float3 V = normalize(-i.worldViewD);
                float3 H = normalize(L+V);
                
                float reflectance = rSchlick(V, N, _Mat1, _Mat2);
                
                //random BRDF? 
                float3 specularity =  pow( max(dot(N,H),0),_Specularity);
                float3 lambert = max(dot(N,L),0);
                float3 ambient =  max(0, ShadeSH9(float4(N, 1)));
                float3 reflect = ambient + specularity* GetSky(V,N,2);
                //random BTDF?
                float3 ndc  = i.pPos.xyz/i.pPos.w;
                ndc.y*=-1;
                float2 uv2 = (ndc+1.0)/2.0;
                float distance = (z(uv2).g -z(uv2).r);
                float3 transmitance = exp(-distance*_Extintion);
                float3 R = refract(V,N,_Mat1/_Mat2);
                float sunAngle = 3*pow(1.0-acos(dot(L,V)),14);//BAD
                float3 ambientR =  max(0, ShadeSH9(float4(R, 1)));
                float3 SSS =(ambientR +(dot(R,L) + sunAngle)*_LightColor0) * transmitance ;
                float3 finalColor = (lambert+
                                     (reflectance * reflect)+
                                     max((1-reflectance) * SSS,0)
                                     )/4*acos(-1); //sphere normalization needed?
                //gamma correct
                return float4(pow(finalColor, float3(1,1,1)*1./2.2),1.0);
            }
            ENDCG
        }
    }
}
