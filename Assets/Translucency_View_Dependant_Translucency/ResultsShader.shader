Shader "Unlit/ResultsShader"
{
    Properties
        {
        _Dens ("Desp", Float) = 0
        }
    SubShader
    {
        Tags { "RenderType"="Transparent" }
        LOD 100

        Pass
        {
            Blend SrcAlpha OneMinusSrcAlpha  
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            
            float _Dens;
            #define z(uv)  tex2D(_DepthDifference,uv)
            #define e float3(1/_ScreenParams.xy  ,0)

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 pPos : TEXCOORD1;
                float4 vertex : SV_POSITION;
            };

            sampler2D _DepthDifference;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.pPos = o.vertex;
                o.uv = v.uv;
                return o;
            }

            float3 N(float2 uv){
                
               float dzdx =  (z(uv+e.xz).g - z(uv-e.xz).g)/2.0  ;
               float dzdy =  (z(uv+e.zy).g - z(uv-e.zy).g)/2.0 ;
               float3 N=float3(-dzdx,-dzdy,-1);
               return N;
            }
            
            float3 GetNormal(float2 uv){

            	float d0 = z(uv).g;
            	float d1 = z(uv+e.xz).g;
            	float d2 = z(uv+e.zy).g;
            	
            	float dx = (d0 - d1) / e.x;
            	float dy = (d0 - d2) / e.y;
            	
            	float3 normal = normalize(float3(dx,dy,d0));
            	
            	return normal;
            }

            
            float3 vN(float3 D, float2 uv){
                float3 vPos = D * z(uv).g;
                float3 ddx = (normalize(D+e.xzz) * z(uv+ e.xz).g) - vPos;
                float3 ddx2 = vPos - (normalize(D-e.xzz) * z(uv- e.xz).g);
                if (abs(ddx.z) > abs(ddx2.z)) {
                    ddx = ddx2;
                }
                
                float3 ddy = (normalize(D+e.zyz) * z(uv+ e.zy).g) - vPos;
                float3 ddy2 = vPos - (normalize(D-e.zyz) * z(uv- e.zy).g);
                if (abs(ddy.z) > abs(ddy2.z)) {
                    ddy = ddy2;
                }
                float3 n = cross(ddx, ddy);

              return normalize(n);
            }
            
            
            float3 worldN(float3 N){
               float4x4 viewTranspose = transpose(UNITY_MATRIX_V);
               float3 worldNormal = mul(viewTranspose, float4(normalize(N), 0)).xyz;
               return normalize(worldNormal);
            }
            
            
            float4 frag (v2f i) : SV_Target
            {
                float3 ndc  = i.pPos.xyz/i.pPos.w;
                ndc.y*=-1;
                float3 D = normalize( ndc);
                
                float2 uv2 = (ndc+1.0)/2.0;
                float3 vPos = D  -z(uv2).g;
                float3 L =  _WorldSpaceLightPos0;
                float3 N =GetNormal(uv2);
                float3 lambert = dot(L,N);
                clip(abs(z(uv2).g)+ abs(z(uv2).r)>1?1:-1);
                float meshDepth = abs(z(uv2).g -z(uv2).r);

                return float4(exp(-meshDepth*_Dens),0,0,1); 
            }
            
            
            
            ENDCG
        }
    }
}
