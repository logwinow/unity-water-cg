Shader "Custom/Water2" {
		
		Properties {
			// vertex
			_VertexWaveCount ("Vertex Wave Count", Int) = 10
			_VertexFrequency ("_VertexFrequency", Float) = 1
			_VertexFrequencyMult ("_VertexFrequencyMult", Float) = 1.12
			_VertexAmplitude ("_VertexAmplitude", Float) = 1
			_VertexAmplitudeMult ("_VertexAmplitudeMult", Float) = 0.88
			_VertexInitialSpeed ("_VertexInitialSpeed", Float) = 2
			_VertexSpeedRamp ("_VertexSpeedRamp", Float) = 1.2
			_VertexSeedIter ("_VertexSeedIter", Float) = 1.2345
			_VertexMaxPeak ("_VertexMaxPeak", Float) = 1.5
			_VertexPeakOffset ("_VertexPeakOffset", Float) = 0.5
			_VertexHeight ("_VertexMaxPeak", Float) = 1.2
			
			// feagment
			_FragmentWaveCount ("Fragment Wave Count", Int) = 10
			_FragmentFrequency ("_FragmentFrequency", Float) = 1
			_FragmentFrequencyMult ("_FragmentFrequencyMult", Float) = 1.12
			_FragmentAmplitude ("_FragmentAmplitude", Float) = 1
			_FragmentAmplitudeMult ("_FragmentAmplitudeMult", Float) = 0.88
			_FragmentInitialSpeed ("_FragmentInitialSpeed", Float) = 2
			_FragmentSpeedRamp ("_FragmentSpeedRamp", Float) = 1.2
			_FragmentSeedIter ("_FragmentSeedIter", Float) = 1.2345
			_FragmentMaxPeak ("_FragmentMaxPeak", Float) = 1.5
			_FragmentPeakOffset ("_FragmentPeakOffset", Float) = 0.5
			_FragmentHeight ("_FragmentHeight", Float) = 1.2
			_FragmentDrag ("_FragmentDrag", Float) = 1.2
			
			// environment
			_EnvironmentMap ("_EnvironmentMap", CUBE) = "white" {}
			
			// color
			_Ambient ("_Ambient", Color) = (1, 1, 1, 1)
			_DiffuseReflectance ("_DiffuseReflectance", Color) = (1, 1, 1, 1)
			_SpecularReflectance ("_SpecularReflectance", Color) = (1, 1, 1, 1)
			_FresnelColor ("_FresnelColor", Color) = (1, 1, 1, 1)
			_TipColor ("_TipColor", Color) = (1, 1, 1, 1)
			_SunColor ("_SunColor", Color) = (1, 1, 1, 1)
			_SunDirection ("_SunDirection", Vector) = (1, 1, 1, 0)
			
			// Fresnel
			_Shininess ("_Shininess", Float) = 500
			_FresnelBias ("_FresnelBias", Float) = 0
			_FresnelStrength ("_FresnelStrength", Float) = 1
			_FresnelShininess ("_FresnelShininess", Float) = 5
			_TipAttenuation ("_TipAttenuation", Float) = 1
			_NormalStrength ("_NormalStrength", Float) = 1
			_FresnelNormalStrength ("_FresnelNormalStrength", Float) = 1
			_SpecularNormalStrength ("_SpecularNormalStrength", Float) = 1
		}

	SubShader {
		Tags {
			"LightMode" = "ForwardBase"
		}

		Pass {

			ZWrite On

			CGPROGRAM

			#pragma vertex vp
			#pragma fragment fp

			#include "UnityPBSLighting.cginc"
            #include "AutoLight.cginc"

			struct VertexData {
				float4 vertex : POSITION;
				float3 normal : NORMAL;
			};

			struct v2f {
				float4 pos : SV_POSITION;
				float3 normal : TEXCOORD1;
				float3 worldPos : TEXCOORD2;
			};

			#define PI 3.14159265358979323846

			float3 
				_SunDirection, 
				_SunColor;

			// vertex
			float 
				_VertexSeed, 
				_VertexSeedIter, 
				_VertexFrequency, 
				_VertexFrequencyMult, 
				_VertexAmplitude, 
				_VertexAmplitudeMult, 
				_VertexInitialSpeed, 
				_VertexSpeedRamp, 
				_VertexDrag, 
				_VertexHeight, 
				_VertexMaxPeak, 
				_VertexPeakOffset;
			int _VertexWaveCount;
				
			// fragment
			float 
				_FragmentSeed, 
				_FragmentSeedIter, 
				_FragmentFrequency, 
				_FragmentFrequencyMult, 
				_FragmentAmplitude, 
				_FragmentAmplitudeMult, 
				_FragmentInitialSpeed, 
				_FragmentSpeedRamp, 
				_FragmentDrag, 
				_FragmentHeight, 
				_FragmentMaxPeak, 
				_FragmentPeakOffset;
			int _FragmentWaveCount;
			
			float 
				_NormalStrength, 
				_FresnelNormalStrength, 
				_SpecularNormalStrength;
				
			float3 
				_Ambient, 
				_DiffuseReflectance, 
				_SpecularReflectance, 
				_FresnelColor, 
				_TipColor;
				
			float 
				_Shininess, 
				_FresnelBias, 
				_FresnelStrength, 
				_FresnelShininess, 
				_TipAttenuation;

			samplerCUBE _EnvironmentMap;

			float3 vertexFBM(float3 v) {
				float f = _VertexFrequency;
				float a = _VertexAmplitude;
				float speed = _VertexInitialSpeed;
				float seed = _VertexSeed;
				float3 p = v;
				float amplitudeSum = 0.0f;

				float h = 0.0f;
				float2 n = 0.0f;
				for (int wi = 0; wi < _VertexWaveCount; ++wi) {
					float2 d = normalize(float2(cos(seed), sin(seed)));

					float x = dot(d, p.xz) * f + _Time.y * speed;
					float wave = a * exp(_VertexMaxPeak * sin(x) - _VertexPeakOffset);
					float dx = _VertexMaxPeak * wave * cos(x);
					
					h += wave;
					
					p.xz += d * -dx * a * _VertexDrag;

					amplitudeSum += a;
					f *= _VertexFrequencyMult;
					a *= _VertexAmplitudeMult;
					speed *= _VertexSpeedRamp;
					seed += _VertexSeedIter;
				}

				float3 output = float3(h, n.x, n.y) / amplitudeSum;
				output.x *= _VertexHeight;

				return output;
			}

			float3 fragmentFBM(float3 v) {
				float f = _FragmentFrequency;
				float a = _FragmentAmplitude;
				float speed = _FragmentInitialSpeed;
				float seed = _FragmentSeed;
				float3 p = v;

				float h = 0.0f;
				float2 n = 0.0f;
				
				float amplitudeSum = 0.0f;

				for (int wi = 0; wi < _FragmentWaveCount; ++wi) {
					float2 d = normalize(float2(cos(seed), sin(seed)));

					float x = dot(d, p.xz) * f + _Time.y * speed;
					float wave = a * exp(_FragmentMaxPeak * sin(x) - _FragmentPeakOffset);
					float2 dw = f * d * (_FragmentMaxPeak * wave * cos(x));
					
					h += wave;
					p.xz += -dw * a * _FragmentDrag;
					
					n += dw;
					
					amplitudeSum += a;
					f *= _FragmentFrequencyMult;
					a *= _FragmentAmplitudeMult;
					speed *= _FragmentSpeedRamp;
					seed += _FragmentSeedIter;
				}
				
				float3 output = float3(h, n.x, n.y) / amplitudeSum;
				output.x *= _FragmentHeight;

				return output;
			}

			float4x4 _CameraInvViewProjection;
			sampler2D _CameraDepthTexture;
			
			float3 ComputeWorldSpacePosition(float2 positionNDC, float deviceDepth) {
				float4 positionCS = float4(positionNDC * 2.0 - 1.0, deviceDepth, 1.0);
				float4 hpositionWS = mul(_CameraInvViewProjection, positionCS);
				return hpositionWS.xyz / hpositionWS.w;
			}

			v2f vp(VertexData v) {
				v2f i;

				i.worldPos = mul(unity_ObjectToWorld, v.vertex);

				float3 h = 0.0f;
				float3 n = 0.0f;

				float3 fbm = vertexFBM(i.worldPos);

				h.y = fbm.x;
				n.xy = fbm.yz;

				float4 newPos = v.vertex + float4(h, 0.0f);
				i.worldPos = mul(unity_ObjectToWorld, newPos);
				i.pos = UnityObjectToClipPos(newPos);

				return i;
			}

			float4 fp(v2f i) : SV_TARGET {
                float3 lightDir = -normalize(_SunDirection);
                float3 viewDir = normalize(_WorldSpaceCameraPos - i.worldPos);
                float3 halfwayDir = normalize(lightDir + viewDir);

				float3 normal = 0.0f;
				float height = 0.0f;

				float3 fbm = fragmentFBM(i.worldPos);
				height = fbm.x;
				normal.xy = fbm.yz;
				
				normal = normalize(UnityObjectToWorldNormal(normalize(float3(-normal.x, 1.0f, -normal.y))));

				normal.xz *= _NormalStrength;
				normal = normalize(normal);

				float ndotl = DotClamped(lightDir, normal);

				float3 diffuseReflectance = _DiffuseReflectance / PI;
                float3 diffuse = _LightColor0.rgb * ndotl * diffuseReflectance;

				// Schlick Fresnel
				float3 fresnelNormal = normal;
				fresnelNormal.xz *= _FresnelNormalStrength;
				fresnelNormal = normalize(fresnelNormal);
				float base = 1 - dot(viewDir, fresnelNormal);
				float exponential = pow(base, _FresnelShininess);
				float R = exponential + _FresnelBias * (1.0f - exponential);
				R *= _FresnelStrength;
				
				float3 fresnel = _FresnelColor * R;

				// environment light
				float3 reflectedDir = reflect(-viewDir, normal);
				float3 skyCol = texCUBE(_EnvironmentMap, reflectedDir).rgb;
				float3 sun = _SunColor * pow(max(0.0f, DotClamped(reflectedDir, lightDir)), 500.0f);

				fresnel = skyCol.rgb * R;
				fresnel += sun * R;


				float3 specularReflectance = _SpecularReflectance;
				float3 specNormal = normal;
				specNormal.xz *= _SpecularNormalStrength;
				specNormal = normalize(specNormal);
				float spec = pow(DotClamped(specNormal, halfwayDir), _Shininess) * ndotl;
                float3 specular = _LightColor0.rgb * specularReflectance * spec;

				// Schlick Fresnel but again for specular
				base = 1 - DotClamped(viewDir, halfwayDir);
				exponential = pow(base, 5.0f);
				R = exponential + _FresnelBias * (1.0f - exponential);

				specular *= R;
				


				float3 tipColor = _TipColor * pow(height, _TipAttenuation);

				float3 output = _Ambient + diffuse + specular + fresnel + tipColor;


				return float4(output, 1.0f);
			}

			ENDCG
		}
	}
}