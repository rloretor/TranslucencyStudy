﻿    #include "UnityCG.cginc"
    #include "UnityLightingCommon.cginc"
       
    #define _Extintion  (_Scattering + _Absorption)
    float3 _Scattering = float3(0.81,2.27,2.62);
    float3 _Absorption = float3(0,0,0);;
    float _Specularity =100;;
    float _Mat1 = 1 ;
    float _Mat2 =3.52;
    
    float distance =0;
    
    float3 SampleSky(float3 R,int lod){
        float4 skyData = UNITY_SAMPLE_TEXCUBE_LOD(unity_SpecCube0, R,lod);
        return  DecodeHDR (skyData, unity_SpecCube0_HDR).xyz;
    }
    
    float3 GetSky(float3 worldViewDir,float3 N,int lod){
        float3 R = reflect(worldViewDir, N);
        return SampleSky(R,lod);             
    }

    float rSchlick(float3 incident, float3 normal, float n1, float n2)
    {
        float r0 = (n1 - n2) / (n1 + n2);
        r0 *= r0;
        float cos  = 1.0 + dot(normal, incident);
        return saturate(r0 + (1.0 - r0) * pow(cos,5.0));
    }     
       
    float BRDF(float3 N, float3 L ,float3 V){
        //Compute Reflected Radiance at point B
        //We use for ambient Unitys Spherical Harmonics wizardry
        //for the rest is a Blinn-Phong BRDF ... ¯\_(ツ)_/¯
        float3 H = normalize(L+V);
        float3 specularity =  pow( max(dot(N,H),0),_Specularity);
        float3 lambert =  max(dot(N,L),0);
        float3 ambient =  max(0, ShadeSH9(float4(N, 1)));
        return ambient + lambert*_LightColor0 + specularity * GetSky(V,N,2);
    }
    
    float3 BTDF(float3 N, float3 L ,float3 V,float distance)
    {
        // volume transport with 1 scattering event
        // Compute Refracted radiance using volume transport/volume rendering equation 
        // We gather Radiance at the other end of the slab same as with the reflected.

        float3 transmitance = saturate(exp(-distance* _Extintion ));
        float3 R = refract(V,N,_Mat1/_Mat2);
        
        float3 ambient =  max(0, ShadeSH9(float4(R, 1)));
        float lambert =  saturate(dot(-N,L));
        float specularity = (pow(saturate(dot(L,V)),800));//BAD,like, totally, the ad hoc sun solid angle probably badly computed.
                                                   //People tend to also call this "artist driven" hehe
        return (ambient + lambert *_LightColor0 + specularity* GetSky(R,-N,2))* transmitance ;
    }