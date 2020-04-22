Shader "Translucency/view_dependant"
{
    Properties
    {
        _Specularity("Specularity", Float) = 100
        [HDR] _Scattering("Scattering Coefficient", Color) = (1,1,1,1)
        [HDR] _Absorption("Absorption Coefficient", Color) = (1,1,1,1)

        _Mat1("Medium 1 Coefficient", Float) = 1
        _Mat2("Medium 2 Coefficient", Float) = 1.33
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
            #include "Assets/Lighting/TranslucentBTDF.cginc"

            #define z(uv)  tex2D(_DepthDifference,uv)            
            
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

            float GetDepthDistance(float2 uv){
             return (z(uv).g -z(uv).r);
            }
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
           
            fixed4 frag (v2f i) : SV_Target
            {
                float3 N = normalize(i.normal);
                float3 L = normalize(_WorldSpaceLightPos0.xyz);
                float3 V = normalize(-i.worldViewD);
 
                float3 ndc  = i.pPos.xyz/i.pPos.w;
                ndc.y*=-1;
                float2 uv2 = (ndc+1.0)/2.0;
                
                //most of this functions are stored in translucent.cginc
                float reflectance = rSchlick(V, N, _Mat1, _Mat2);
                distance = GetDepthDistance(uv2);
                float3 reflectedRadiance = BRDF(N,L,V,1);
                float3 refractedRadiance = BTDF(N,L,V,distance,1);
             
                float3 finalColor = ((reflectance *reflectedRadiance) + (refractedRadiance*(1.0-reflectance)));

                return finalColor.xyzz;
                //float4(pow(finalColor, 1./2.2),1.0); no gamma, too bright 
            }
            ENDCG
        }
    }
}
