Shader "Custom/WaterTessellated"
{
    Properties
    {
		_WavesCount ("Waves count", Integer) = 1
		_DirectionAngle("Direction", Float) = 0
		_Wavelength("Wavelength", Float) = 1
		_Pressure("Pressure", Float) = 0
		_Speed("Speed", Float) = 1
		_fbmAmplitudeMult("fBM Amplitude multiplier", Float) = 0.82
		_fbmFrequencyMult("fBM Frequency multiplier", Float) = 0.7
		_Seed("Seed", Integer) = 0
		_BaseColor("Base color", Color) = (1, 1, 1, 1)
		_SunDirection("Sun direction", Vector) = (1, 1, 1, 0)
    }
	
	CGINCLUDE
        #define _TessellationEdgeLength 10
		#define NEW_LIGHTING

        struct TessellationFactors {
            float edge[3] : SV_TESSFACTOR;
            float inside : SV_INSIDETESSFACTOR;
        };

        float TessellationHeuristic(float3 cp0, float3 cp1) {
            float edgeLength = distance(cp0, cp1);
            float3 edgeCenter = (cp0 + cp1) * 0.5;
            float viewDistance = distance(edgeCenter, _WorldSpaceCameraPos);

            return edgeLength * _ScreenParams.y / (_TessellationEdgeLength * (pow(viewDistance * 0.5f, 1.2f)));
        }

        bool TriangleIsBelowClipPlane(float3 p0, float3 p1, float3 p2, int planeIndex, float bias) {
            float4 plane = unity_CameraWorldClipPlanes[planeIndex];

            return dot(float4(p0, 1), plane) < bias && dot(float4(p1, 1), plane) < bias && dot(float4(p2, 1), plane) < bias;
        }

        bool cullTriangle(float3 p0, float3 p1, float3 p2, float bias) {
            return TriangleIsBelowClipPlane(p0, p1, p2, 0, bias) ||
                   TriangleIsBelowClipPlane(p0, p1, p2, 1, bias) ||
                   TriangleIsBelowClipPlane(p0, p1, p2, 2, bias) ||
                   TriangleIsBelowClipPlane(p0, p1, p2, 3, bias);
        }
    ENDCG
	
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
			
			#pragma target 5.0
			#pragma vertex dummyvp
            #pragma vertex vp
			#pragma hull hp
			#pragma domain dp 
			#pragma geometry gp
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"
			
			#define PI 3.14159265359
			
			struct TessellationControlPoint {
                float4 vertex : INTERNALTESSPOS;
                float2 uv : TEXCOORD0;
            };

            struct VertexData
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };
			
			struct v2g {
				float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
				float3 worldPos : TEXCOORD1;
				float depth : TEXCOORD2;
				float3 normal : NORMAL;
			};

            struct g2f
            {
                // float2 uv : TEXCOORD0;
                // UNITY_FOG_COORDS(1)
                // float4 vertex : SV_POSITION;
				float3 normal : NORMAL;
				v2g data;
				float2 barycentricCoordinates : TEXCOORD9;
            };
			
			int 
				_WavesCount,
				_Seed;
			float 
				_DirectionAngle,
				_Wavelength,
				_Speed,
				_Pressure,
				_fbmAmplitudeMult,
				_fbmFrequencyMult;
			float4 _BaseColor;
			float4 _SunDirection;
			
			float rand(int seedOffset)
			{
				return frac(sin((_Seed + seedOffset) * 12.9898) * 43758.5453123);
			}
			
			float3 getWaterPoint(float3 position, out float3 normal)
			{
				float3 result = position;
				float f = 1;
				float a = 1;
				float dx = 0;
				float dz = 0;
				float dy = 0;
				float3 tangent = float3(1, 0, 0);
				float3 binormal = float3(0, 0, 1);
				
				for (int i = 0; i < _WavesCount; i++)
				{
					float angle = _DirectionAngle + (i > 0 ? 2 * PI * rand(i) : 0);
					
					float2 dir = normalize(float2(cos(angle), sin(angle)));
					float k = 2 * PI / _Wavelength;
					float q = exp(k * _Pressure) / k;
					float d = dot(dir, position.xz);
					float phaseSpeed = k * _Speed;
					float phase = 2 * PI * rand(i);
					float periodicalExpression = k * (d * f + phaseSpeed * _Time.y) + phase;
					
					result += float3(
						dir.x * q * cos(periodicalExpression),
						a * q * sin(periodicalExpression),
						dir.y * q * cos(periodicalExpression)
					);
					
					tangent += float3(
						- dir.x * q * sin(periodicalExpression) * k * dir.x * f,
						a * q * cos(periodicalExpression) * k * dir.x * f,
						- dir.y * q * sin(periodicalExpression) * k * dir.x * f
					);
					
					binormal += float3(
						- dir.x * q * sin(periodicalExpression) * k * dir.y * f,
						a * q * cos(periodicalExpression) * k * dir.y * f,
						- dir.y * q * sin(periodicalExpression) * k * dir.y * f
					);
					
					f *= _fbmFrequencyMult;
					a *= _fbmAmplitudeMult;
				}
				
				normal = normalize(cross(binormal, tangent));
				// normal = dot(normalize(tangent), binormal));
				
				return result;
			}
			
			TessellationControlPoint dummyvp(VertexData v) {
				TessellationControlPoint p;
				p.vertex = v.vertex;
				p.uv = v.uv;

				return p;
			}

            v2g vp (VertexData v)
            {
                v2g o;
				float3 normal;
				float3 waterPoint = getWaterPoint(v.vertex, normal);
				o.pos = UnityObjectToClipPos(waterPoint);
				//o.normal = UnityObjectToWorldNormal(normal);
                o.uv = v.uv;
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }
			
			TessellationFactors PatchFunction(InputPatch<TessellationControlPoint, 3> patch) {
                float3 p0 = mul(unity_ObjectToWorld, patch[0].vertex);
                float3 p1 = mul(unity_ObjectToWorld, patch[1].vertex);
                float3 p2 = mul(unity_ObjectToWorld, patch[2].vertex);

                TessellationFactors f;
                float bias = -0.5 * 100;
                if (cullTriangle(p0, p1, p2, bias)) {
                    f.edge[0] = f.edge[1] = f.edge[2] = f.inside = 0;
                } else {
                    f.edge[0] = TessellationHeuristic(p1, p2);
                    f.edge[1] = TessellationHeuristic(p2, p0);
                    f.edge[2] = TessellationHeuristic(p0, p1);
                    f.inside = (TessellationHeuristic(p1, p2) +
                                TessellationHeuristic(p2, p0) +
                                TessellationHeuristic(p1, p2)) * (1 / 3.0);
                }
                return f;
            }

            [UNITY_domain("tri")]
            [UNITY_outputcontrolpoints(3)]
            [UNITY_outputtopology("triangle_cw")]
            [UNITY_partitioning("integer")]
            [UNITY_patchconstantfunc("PatchFunction")]
            TessellationControlPoint hp(InputPatch<TessellationControlPoint, 3> patch, uint id : SV_OUTPUTCONTROLPOINTID) {
                return patch[id];
            }
			
			[maxvertexcount(3)]
            void gp(triangle v2g g[3], inout TriangleStream<g2f> stream) {
                g2f g0, g1, g2;
                g0.data = g[0];
                g1.data = g[1];
                g2.data = g[2];

                g0.barycentricCoordinates = float2(1, 0);
                g1.barycentricCoordinates = float2(0, 1);
                g2.barycentricCoordinates = float2(0, 0);

                stream.Append(g0);
                stream.Append(g1);
                stream.Append(g2);
            }

            #define DP_INTERPOLATE(fieldName) data.fieldName = \
                data.fieldName = patch[0].fieldName * barycentricCoordinates.x + \
                                 patch[1].fieldName * barycentricCoordinates.y + \
                                 patch[2].fieldName * barycentricCoordinates.z;               

            [UNITY_domain("tri")]
            v2g dp(TessellationFactors factors, OutputPatch<TessellationControlPoint, 3> patch, float3 barycentricCoordinates : SV_DOMAINLOCATION) {
                VertexData data;
                DP_INTERPOLATE(vertex)
                DP_INTERPOLATE(uv)

                return vp(data);
            }

            fixed4 frag (g2f i) : SV_Target
            {
                // sample the texture
                fixed4 col = _BaseColor * float4(lerp(0.2, 1, (dot(-i.normal, normalize(_SunDirection.xyz)) + 1) / 2).xxx, 1);
                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG
        }
    }
}
