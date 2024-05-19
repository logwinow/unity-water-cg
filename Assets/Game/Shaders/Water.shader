Shader "Custom/Water"
{
    Properties
    {
		[StyledBanner(Water shader)] 
		_WaterBanner("_WaterBanner", Float) = 1
		
		// general
		[StyledCategory(General settings, 5, 10)]
		_GeneralCategory("_GeneralCategory", Float) = 1
		_DirectionAngle("Direction", Float) = 0
		_Wavelength("Wavelength", Float) = 1
		_Pressure("Pressure", Float) = 0
		_SpeedMultiplier("Speed multiplier", Float) = 1
		_fbmAmplitudeMult("fBM Amplitude multiplier", Float) = 0.82
		_fbmFrequencyMult("fBM Frequency multiplier", Float) = 0.7
		_Seed("Seed", Float) = 0.0
		[Toggle(_NORMAL_PER_VERTEX)] _NormalPerVertex("Enable normal per vertex", Float) = 0
		[Toggle(_DIFFUSE_ENABLED)] _DiffuseEnabled("Enable diffuse", Float) = 1
		[Toggle(_SPECULAR_ENABLED)] _SpecularEnabled("Enable specular", Float) = 1
		[Toggle(_AMBIENT_ENABLED)] _AmbientEnabled("Enable ambient", Float) = 1
		[Toggle(_ENVIRONMENT_REFLECTION_ENABLED)] _EnvironmentReflectionEnabled("Enable evironment reflection", Float) = 1
		[Toggle(_FRESNEL_ENABLED)] _FresnelEnabled("Enable Fresnel", Float) = 1
		
		// fragment general
		[StyledCategory(Fragment general settings, 5, 10)]
		_FragmentGeneralCategory("_FragmentGeneralCategory", Float) = 1
		_BaseColor("Base color", Color) = (1, 1, 1, 1)
		_Ambient("Ambient", Color) = (1, 1, 1, 1)
		_FragmentWavesCount ("Fragment waves count", Integer) = 1
		_NormalStrength("Normal strength", Float) = 1
		
		// vertex general
		[StyledCategory(Vertex general settings, 5, 10)]
		_VertexGeneralCategory("_VertexGeneralCategory", Float) = 1
		_VertexWavesCount ("Vertex waves count", Integer) = 1
		
		// diffuse
		[Space(10)]
		[StyledCategory(Diffuse settings, 5, 10)]
		_DiffuseCategory("_DiffuseCategory", Float) = 1
		_DiffuseNormalStrength("Diffuse normal strength", Float) = 1
		
		// environment reflection
		[Space(10)]
		[StyledCategory(Environemnt reflection settings, 5, 10)]
		_EnvironmentReflectionCategory("_EnvironmentReflectionCategory", Float) = 1
		_EnvironmentMap("Environment map", CUBE) = "white" {}
		_FresnelEnvironmentReflectionBias("Fresnel environment reflection bias", Float) = 1
		_EnvironmentReflectionNormalStrength("Environment reflection normal strength", Float) = 1
		_FresnelEnvironmentReflectionStrength("Fresnel environment reflection strength", Float) = 1
		_FresnelEnvironmentReflectionPower("Fresnel environment reflection power", Float) = 6
		
		// specular
		[Space(10)]
		[StyledCategory(Specular settings, 5, 10)]
		_SpecularCategory("_SpecularCategory", Float) = 1
		_Shiness("Shiness", Float) = 64
		_SpecularNormalStrength("Specular normal strength", Float) = 1
		_FresnelSpectacularStrength("Fresnel spectacular strength", Float) = 1
		_FresnelSpectacularBias("Fresnel spectacular bias", Float) = 1
		_FresnelSpectacularPower("Fresnel spectacular power", Float) = 15
    }
	
    SubShader
    {
        Tags 
		{ 
			"RenderType"="Opaque" 
			"LightMode"="ForwardBase" 
		}

        Pass
        {
			ZWrite On
		
            CGPROGRAM
			
			#pragma multi_compile_fog
            #pragma vertex vert
            #pragma fragment frag
			
			#pragma shader_feature_local _NORMAL_PER_VERTEX
			#pragma shader_feature_local _DIFFUSE_ENABLED
			#pragma shader_feature_local _SPECULAR_ENABLED
			#pragma shader_feature_local _AMBIENT_ENABLED
			#pragma shader_feature_local _ENVIRONMENT_REFLECTION_ENABLED
			#pragma shader_feature_local _FRESNEL_ENABLED

            #include "UnityCG.cginc"
            #include "UnityLightingCommon.cginc"
			
			#define GRAVITY 9.80665
			
			struct appdata
            {
                float4 vertex : POSITION;
            };

            struct v2f
            {
				float4 vertex : SV_POSITION;
				float3 worldPos : TEXCOORD0;
				UNITY_FOG_COORDS(1)
			#ifdef _NORMAL_PER_VERTEX
				float3 normal : NORMAL;
			#endif
            };
			
			// environment reflection
			samplerCUBE _EnvironmentMap;
			float
				_EnvironmentReflectionNormalStrength,
				_FresnelEnvironmentReflectionPower,
				_FresnelEnvironmentReflectionBias,
				_FresnelEnvironmentReflectionStrength;
			
			// specular
			float
				_FresnelSpectacularBias,
				_FresnelSpectacularStrength,
				_FresnelSpectacularPower,
				_SpecularNormalStrength,
				_Shiness;
				
			// diffuse
			float
				_DiffuseNormalStrength;
			
			// general
			int 
				_FragmentWavesCount,
				_VertexWavesCount;
				
			float 
				_DirectionAngle,
				_Wavelength,
				_SpeedMultiplier,
				_Pressure,
				_fbmAmplitudeMult,
				_fbmFrequencyMult,
				_Seed,
				_NormalStrength;
				
			fixed4 
				_BaseColor,
				_Ambient;
			
			float random(float seedOffset)
			{
				return frac(((_Seed + seedOffset) * 2.14069) * 2.66514);
			}
			
			float getPhaseSpeed(float k)
			{
				float c = sqrt(GRAVITY / k);
				
				return c * _SpeedMultiplier;
			}
			
			float3 gerstner(float3 position)
			{
				float3 result = 0;
				float f = 1.0;
				float a = 1.0;
				float k = 2.0 * UNITY_PI / _Wavelength;
				float q = exp(k * _Pressure) / k;
				float phaseSpeed = getPhaseSpeed(k);
				
				for (int i = 0; i < _VertexWavesCount; i++)
				{
					float angle = _DirectionAngle + (i > 0 ? 2.0 * UNITY_PI * random(i) : 0);
					float2 dir = normalize(float2(cos(angle), sin(angle)));
					float qa = a * q;
					float d = dot(dir, position.xz);
					float phase = 2 * UNITY_PI * random(i + _VertexWavesCount);
					float periodicalExpression = k * (d * f + phaseSpeed * _Time.y) + phase;
					float cosPE = qa * cos(periodicalExpression);
					float sinPE = qa * sin(periodicalExpression);
					
					result += float3(
						dir.x * cosPE,
						sinPE,
						dir.y * cosPE
					);
					
					f *= _fbmFrequencyMult;
					a *= _fbmAmplitudeMult;
				}
				
				return result;
			}
			
			float3 gerstnerNormal(float3 position) 
			{
				float f = 1.0;
				float a = 1.0;
				float k = 2.0 * UNITY_PI / _Wavelength;
				float q = exp(k * _Pressure) / k;
				float phaseSpeed = getPhaseSpeed(k);
				float3 tangent = float3(1.0, 0, 0);
				float3 binormal = float3(0, 0, 1.0);
				
				for (int i = 0; i < _FragmentWavesCount; i++)
				{
					float angle = _DirectionAngle + (i > 0 ? 2.0 * UNITY_PI * random(i) : 0);
					float2 dir = normalize(float2(cos(angle), sin(angle)));
					float qa = a * q;
					float d = dot(dir, position.xz);
					float phase = 2 * UNITY_PI * random(i + _VertexWavesCount);
					float periodicalExpression = k * (d * f + phaseSpeed * _Time.y) + phase;
					float cosPE = qa * cos(periodicalExpression);
					float sinPE = qa * sin(periodicalExpression);
					
					float3 sameDerivativeDelta = float3(
						- dir.x * sinPE,
						cosPE,
						- dir.y * sinPE
					) * k * f;
					
					tangent += sameDerivativeDelta * dir.x;
					binormal += sameDerivativeDelta * dir.y;
					
					f *= _fbmFrequencyMult;
					a *= _fbmAmplitudeMult;
				}
				
				return normalize(cross(binormal, tangent)); // normal
			}

            v2f vert (appdata v)
            {
                v2f o;
				
				o.worldPos = mul(unity_ObjectToWorld, v.vertex);
				o.vertex = UnityObjectToClipPos(gerstner(o.worldPos) + v.vertex);
				
			#ifdef _NORMAL_PER_VERTEX
				o.normal = gerstnerNormal(o.worldPos);
			#endif
				
				UNITY_TRANSFER_FOG(o, o.vertex);
				
                return o;
            }
			
			float SchlickFresnel(float bias, float3 v, float3 n, float fresnelPower) 
			{
				return lerp(bias, 1.0, pow(1 - dot(v, n), fresnelPower));
			}
			
			float3 StrengthNormal(float3 normal, float strength)
			{
				normal.y *= strength;
				return normalize(normal);
			}

            fixed4 frag (v2f i) : SV_Target
            {
				fixed4 color = fixed4(0, 0, 0, 1);
				
				// ambient
			#ifdef _AMBIENT_ENABLED
				color += fixed4(_Ambient.xyz, 0);
			#endif
				
			#ifdef _NORMAL_PER_VERTEX
				float3 normal = i.normal;
			#else
				float3 normal = StrengthNormal(gerstnerNormal(i.worldPos), _NormalStrength);
			#endif
				
				float3 sunDir = _WorldSpaceLightPos0.xyz;
				float3 cameraDirection = normalize(_WorldSpaceCameraPos - i.worldPos);
				
				// diffuse
			#ifdef _DIFFUSE_ENABLED
				float3 diffuseNormal = StrengthNormal(normal, _DiffuseNormalStrength);
				float diffuse = clamp(dot(diffuseNormal, sunDir), 0, 1); // Lambertian reflectance
				fixed4 diffuseCol = fixed4(diffuse * _BaseColor.xyz, 0);
				color += diffuseCol;
			#endif
				
				// specular
		#ifdef _SPECULAR_ENABLED
				float3 specularNormal = StrengthNormal(normal, _SpecularNormalStrength);
				float3 sunReflection = reflect(-sunDir, specularNormal);
				float specular = pow(clamp(dot(sunReflection, cameraDirection), 0, 1), _Shiness);
				fixed3 specularCol = specular * _LightColor0.xyz;
			#ifdef _FRESNEL_ENABLED
				float specularFresnel = SchlickFresnel(_FresnelSpectacularBias, cameraDirection, diffuseNormal, _FresnelSpectacularPower) * _FresnelSpectacularStrength;
				specularCol *= specularFresnel;
			#endif
				color += fixed4(specularCol, 0);
		#endif
				
				// environment reflection
		#ifdef _ENVIRONMENT_REFLECTION_ENABLED
				float3 environmentReflectionNormal = StrengthNormal(normal, _EnvironmentReflectionNormalStrength);
				float3 reflectedDir = reflect(-cameraDirection, environmentReflectionNormal);
				fixed3 environmentReflectionCol = texCUBE(_EnvironmentMap, reflectedDir).xyz;
			#ifdef _FRESNEL_ENABLED
				float environmentReflectionFresnel = SchlickFresnel(_FresnelEnvironmentReflectionBias, cameraDirection, environmentReflectionNormal, _FresnelEnvironmentReflectionPower) * _FresnelEnvironmentReflectionStrength;
				environmentReflectionCol *= environmentReflectionFresnel;
			#endif
				color += fixed4(environmentReflectionCol, 0);
		#endif
				
				UNITY_APPLY_FOG(i.fogCoord, color);
				
                return color; 
            }
            ENDCG
        }
		//SHADOW CASTER PASS
		// to write into depth buffer
        Pass
        {
            Tags {"LightMode" = "ShadowCaster"}
            ZWrite On
        }
    }
}
