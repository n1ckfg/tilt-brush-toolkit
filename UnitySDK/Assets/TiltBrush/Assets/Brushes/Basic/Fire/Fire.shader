// Copyright 2017 Google Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

Shader "Brush/Special/Fire" {
Properties {
	_MainTex ("Particle Texture", 2D) = "white" {}
	_Scroll1 ("Scroll1", Float) = 0
	_Scroll2 ("Scroll2", Float) = 0
	_DisplacementIntensity("Displacement", Float) = .1
    _EmissionGain ("Emission Gain", Range(0, 1)) = 0.5
}

Category {
	Tags { "Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent" }
	Blend One One // SrcAlpha One
	BlendOp Add, Min
	ColorMask RGBA
	Cull Off Lighting Off ZWrite Off Fog { Color (0,0,0,0) }
	
	SubShader {
		Pass { 
		 
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma target 3.0
			#pragma multi_compile_particles
			#pragma multi_compile __ AUDIO_REACTIVE 
			#pragma shader_feature FORCE_SRGB

			#include "UnityCG.cginc"
			#include "../../../Shaders/Brush.cginc"

			sampler2D _MainTex;
			
			struct appdata_t {
				float4 vertex : POSITION;
				fixed4 color : COLOR;
				float3 normal : NORMAL;
				centroid float2 texcoord : TEXCOORD0;
				float3 worldPos : TEXCOORD1;
			};

			struct v2f {
				float4 vertex : POSITION;
				float4 color : COLOR; 
				centroid float2 texcoord : TEXCOORD0;
				float3 worldPos : TEXCOORD1;
			};
			
			float4 _MainTex_ST;
			fixed _Scroll1;
			fixed _Scroll2;
			half _DisplacementIntensity;
			half _EmissionGain;

			v2f vert (appdata_t v)
			{
				v2f o;
				o.texcoord = TRANSFORM_TEX(v.texcoord,_MainTex);
				o.color = bloomColor(v.color, _EmissionGain);
				o.vertex = mul(UNITY_MATRIX_MVP, v.vertex);
				o.worldPos = mul(unity_ObjectToWorld, v.vertex);
				return o; 
			}
		
			fixed4 frag (v2f i) : COLOR 
			{
				i.color = ensureColorSpace(i.color);
				half2 displacement;
				float procedural_line = 0;
#ifdef AUDIO_REACTIVE
				// Envelope
				float envelope = sin(i.texcoord.x * 3.14159);
				float envelopeHalf = sin(i.texcoord.x * 3.14159 * .5);

				// Basic fire effect
				displacement = tex2D(_MainTex, i.texcoord + half2(-_Time.x * _Scroll1, 0)  ).a; 

				// Waveform fire effect
				float waveform = (tex2D(_WaveFormTex, float2(i.texcoord.x * .2 + .025*i.worldPos.y,0)).g - .5f) + displacement*.05;
				procedural_line = pow(abs(1 - abs((i.texcoord.y - .5) + waveform)), max(100 * i.texcoord.x, 0.001)); 

				waveform = (tex2D(_WaveFormTex, float2(i.texcoord.x * .3 + .034*i.worldPos.y,0)).w - .5f) + displacement*.02;
				procedural_line += pow(abs(1 - abs((i.texcoord.y - .5) + waveform)), max(100 * i.texcoord.x, 0.001)); 

				//procedural_line = saturate(1 - 10*abs(i.texcoord.y - .5 + waveform * envelopeHalf));
				//procedural_line = pow(procedural_line, i.texcoord.x* 10); 

#else
			 	displacement = tex2D(_MainTex, i.texcoord + half2(-_Time.x * _Scroll1, 0)  ).a; 
#endif

	 			half4 tex = tex2D(_MainTex, i.texcoord + half2(-_Time.x * _Scroll2, 0) - displacement * _DisplacementIntensity);		
#ifdef AUDIO_REACTIVE
				tex = tex * .5 + 2 * procedural_line * ( envelope * envelopeHalf);
#endif
				float4 color = i.color * tex;
				return float4(color.rgb * color.a, 1.0);
			}
			ENDCG 
		}
	}	
}
}
