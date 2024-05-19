Shader "Custom/SingleGerstnerWaveWater"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
		_DirectionAngle("Direction", Float) = 0
		_Wavelength("Wavelength", Float) = 1
		_Pressure("Pressure", Float) = 0
		_Speed("Speed", Float) = 1
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };
			
			#define PI 3.14159265359

            struct v2f
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
            };
			
            sampler2D _MainTex;
            float4 _MainTex_ST;
			
			float _DirectionAngle;
			float _Wavelength;
			float _Speed;
			float _Pressure;
			
			float3 getWaterPoint(float3 position)
			{
				float2 direction = float2(cos(_DirectionAngle), sin(_DirectionAngle));
				float k = 2 * PI / _Wavelength;
				float q = exp(k * _Pressure) / k;
				float d = dot(direction, position.xz);
				
				return float3(
					position.x + direction.x * q * cos(k * (d + _Speed * _Time.y)),
					position.y + q * sin(k * (d + _Speed * _Time.y)),
					position.z + direction.y * q * cos(k * (d + _Speed * _Time.y))
				);
			}

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(getWaterPoint(v.vertex));
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv);
                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG
        }
    }
}
