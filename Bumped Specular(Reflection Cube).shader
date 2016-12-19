Shader "Tianyu Shaders/Ground/Bumped Specular(Reflection Cube)" 
{
	Properties
	{
		[Header(Shader COMMON)]
		[KeywordEnum(Off, ON)] _Crossfade("LOD CrossFade mode", Float) = 0
		[Space][Space]
		[Header(Shader Base)]
		_Color("Main Color", Color) = (1,1,1,1)
		_SpecColor("Specular Color", Color) = (0.5, 0.5, 0.5, 1)
		_Shininess("Shininess", Range(0.15, 1)) = 0.2
		[Space][Space][Space]
		
		[Header(Shader Base Texture fetch)]
		_MainTex("Base (RGB)", 2D) = "white" {}
		_BumpMap("Normalmap", 2D) = "bump" {}
		_ParamTex("Occlusion(R) , Specular(G) , Reflection mask (B)", 2D) = "white" {}
		[Space][Space][Space][Space][Space][Space]
        
		[Header(Reflection of Cubemap)]
		[KeywordEnum(Off, ReflectionCubemap)] _Reflective("Reflection mode", Float) = 0
		_ReflectionCube ("Reflection Cubemap", Cube) = "" {  }
		_ReflectiveScale ("Reflection IBL Scale" , Range(0.1,1.5)) =1.0
		

	}

	SubShader
	{
		
    Tags { "Queue"="Geometry" "RenderType" = "Opaque"}
        LOD 400
		Cull [_Cull]
		
		CGPROGRAM
		#pragma fragmentoption ARB_precision_hint_fastest
        #pragma multi_compile _REFLECTIVE_REFLECTIONCUBEMAP _REFLECTIVE_OFF
		
		#pragma surface surf BlinnPhong vertex:vert
		
		#pragma multi_compile __ LOD_FADE_PERCENTAGE LOD_FADE_CROSSFADE
		#pragma multi_compile _CROSSFADE_OFF _CROSSFADE_ON
		#include "UnityCG.cginc"
		#pragma target 3.0
		
	


		struct Input 
		{
			float2 uv_MainTex;
			float2 uv_BumpMap;
			float4 pos : SV_POSITION;
			float3 worldRefl;
			INTERNAL_DATA
			UNITY_DITHER_CROSSFADE_COORDS_IDX(2)
		};


        sampler2D_half _MainTex;
        sampler2D_half _BumpMap;
        sampler2D_half _ParamTex;
        fixed4 _Color;
		//Reflec Cubemap value at below.
        samplerCUBE _ReflectionCube;
		half _ReflectiveScale;
        half _Shininess;


		//VertexShader for the SurfaceShader on unity3D.
		void vert (inout appdata_full v , out Input o) 
		{
			UNITY_INITIALIZE_OUTPUT(Input,o);
			o.pos = mul (UNITY_MATRIX_MVP, v.vertex);
			#ifdef _CROSSFADE_ON
			UNITY_TRANSFER_DITHER_CROSSFADE_HPOS(o, o.pos)
			#endif
	
		}

      
		void surf(Input IN, inout SurfaceOutput o) 
		{
			fixed4 tex = tex2D(_MainTex, IN.uv_MainTex);
			
			fixed4 param_tex = tex2D(_ParamTex, IN.uv_MainTex);
			o.Albedo = tex.rgb * _Color.rgb * param_tex.r;
			o.Gloss = param_tex.g;
            o.Normal = UnpackNormal(tex2D(_BumpMap, IN.uv_BumpMap));
            
			//Cubemap Reflection
			float3 worldRefl = WorldReflectionVector (IN, o.Normal);
            fixed3 reflcol = texCUBE (_ReflectionCube, worldRefl);
			

            o.Specular = _Shininess;
            #ifdef _REFLECTIVE_REFLECTIONCUBEMAP
            o.Emission = (reflcol * _ReflectiveScale * o.Specular * (_SpecColor  * 0.5 + 0.5)) * param_tex.b;
            #endif
			#ifdef _CROSSFADE_ON
			UNITY_APPLY_DITHER_CROSSFADE(IN)
			#endif
           
			

            
		}
		ENDCG
	}
		FallBack "Legacy Shaders/Specular"
}
