Shader "Custom/Outline"
{
    Properties
    {
        _Color1("Color 1", Color) = (1, 0, 0, 1)
        _Color2("Color 2", Color) = (0, 0, 1, 1)
        _MainTex("Main Texture", 2D) = "white"{}
        _Speed("Speed", float) = 1.0
        _Frequency("Frequency", float) = 1.0
        _Amplitude("Wave height", float) = 0.1
        _TextureInfluence("Texture Influence", Range(0, 1)) = 0.2
        _NoiseAnimSpeed("Noise Animation Speed", float) = 1.0
        _NoiseAnimHeight("Noise Animation Height", Range(0, 1)) = 0.5
        _HeightRangeAdjust("Height Range Adjustment", Range(0.5, 2.0)) = 1.0
        _SpatialFreq("Spatial Frequency", float) = 2.0
        _AnimVariation("Animation Variation", Range(0, 1)) = 0.5
    }

    SubShader
    {
        Tags{
       "Queue" = "Transparent"
       "RenderType" = "Transparent"
       "IgnoreProjector" = "True"
       }

        LOD 100
        CULL OFF

        Pass
        {
            Blend SrcAlpha OneMinusSrcAlpha
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            uniform sampler2D _MainTex;
            uniform float4 _MainTex_ST;
            uniform float4 _Color1;
            uniform float4 _Color2;
            uniform float _Speed;
            uniform float _Frequency;
            uniform float _Amplitude;
            uniform float _TextureInfluence;
            uniform float _NoiseAnimSpeed;
            uniform float _NoiseAnimHeight;
            uniform float _HeightRangeAdjust;
            uniform float _SpatialFreq;
            uniform float _AnimVariation;

            struct appdata
            {
                float4 vertex: POSITION;
                float4 normal: NORMAL;
                float4 texcoord: TEXCOORD0;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float4 texcoord: TEXCOORD0;
                float displacement : TEXCOORD2;
                float finalLocalPosY : TEXCOORD1;      
                float originalLocalPosY : TEXCOORD3;   
                float waveAmplitude : TEXCOORD4;       
            };

            float4 _Color;

            v2f vert (appdata v)
            {
                v2f o;
                
                float originalY = v.vertex.y;
                
                // Animate texture coordinates for horizontal scrolling
                v.texcoord.x = (v.texcoord.x + (_Time.y * -0.15 *_Speed) *_Frequency * _Amplitude);
                
                // Main sine wave animation
                float waveDisplacement = sin((v.texcoord.x - _Time.y * _Speed) *_Frequency) * _Amplitude;
                v.vertex.y = v.vertex.y + waveDisplacement;
                
                float displacement = tex2Dlod(_MainTex, v.texcoord * _MainTex_ST);
                
                // Create spatial variation so wavelets are less uniform
                float2 spatialCoord = float2(v.vertex.x, v.vertex.z) * _SpatialFreq;
                float timeOffset = sin(spatialCoord.x) * cos(spatialCoord.y) * _AnimVariation * 3.14159; ///Here
                
                // Animate noise displacement up and down with spatial variation
                float noiseAnimFactor = clamp(sin((_Time.y * _NoiseAnimSpeed)), 0.1, 1) + timeOffset; 
                float animatedDisplacement = displacement;
                animatedDisplacement = animatedDisplacement + displacement * noiseAnimFactor * _NoiseAnimHeight;
                
                o.displacement = animatedDisplacement;
                
                // Track final position for height-based coloring
                float finalLocalY = originalY + waveDisplacement + (animatedDisplacement * _Amplitude);
                
                o.vertex = UnityObjectToClipPos(v.vertex + (v.normal * animatedDisplacement * _Amplitude));
                o.texcoord.xy = (v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw);
                
                o.finalLocalPosY = finalLocalY;
                o.originalLocalPosY = originalY;
                o.waveAmplitude = _Amplitude * _HeightRangeAdjust;

                return o;
            }

            half4 frag (v2f i) : COLOR
            {
                // Calculate dynamic height range for coloring
                float minHeight = i.originalLocalPosY - i.waveAmplitude;
                float maxHeight = i.originalLocalPosY + i.waveAmplitude;
                
                // Create gradient based on current height within range
                float heightGradient = saturate((i.finalLocalPosY - minHeight) / (maxHeight - minHeight));
                
                // Texture influence to gradient
                float modifiedGradient = heightGradient + (i.displacement - 0.5) * _TextureInfluence;
                modifiedGradient = saturate(modifiedGradient);
                
                return lerp(_Color2, _Color1, modifiedGradient);
            }
            ENDCG
        }
    }
}






