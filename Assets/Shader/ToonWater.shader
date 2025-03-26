Shader "Unlit/ToonWater"
{
    Properties
    {
        _NoiseTex ("Texture", 2D) = "white" {}
        _ShallowColor("Depth Color Shallow", Color) = (0.325, 0.807, 0.971, 0.725)
        _DeepColor("Depth Color Deep", Color) = (0.086, 0.407, 1, 0.749)
        _DepthMaxDistance("Depth Maximum Distance", Float) = 1
        _SurfaceNoiseCutoff("Surface Noise Cutoff", Range(0, 1)) = 0.777
        _FoamDistance("Shore Foam", float) = 10

        _SpeedX("SpeedX", Range(-1, 1)) = 0.2
        _SpeedY("SpeedY", Range(-1, 1)) = 0

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

            #include "UnityCG.cginc"

            float4 _ShallowColor;
            float4 _DeepColor;
            float _DepthMaxDistance;
            sampler2D _CameraDepthTexture;
            sampler2D _NoiseTex;
            float4 _NoiseTex_ST;
            float _SurfaceNoiseCutoff;
            float _FoamDistance;
            uniform float _SpeedX;
            uniform float _SpeedY;


            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float4 screenPosition : TEXCOORD2;
                float2 noiseUV : TEXCOORD0;

            };

            v2f vert (appdata v)
            {
                v2f o;
                v.uv.x = (v.uv.x + (_Time.y * -0.15 *_SpeedX));
                v.uv.y = (v.uv.y + (_Time.y * -0.15 *_SpeedY));
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.screenPosition = ComputeScreenPos(o.vertex);
                o.noiseUV.xy = (v.uv.xy * _NoiseTex_ST.xy + _NoiseTex_ST.zw);
                o.noiseUV = TRANSFORM_TEX(v.uv, _NoiseTex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
               float existingDepth01 = tex2Dproj(_CameraDepthTexture, UNITY_PROJ_COORD(i.screenPosition)).r;
               float existingDepthLinear = LinearEyeDepth(existingDepth01);
               float depthDifference = existingDepthLinear - i.screenPosition.w;
               float waterDepthDifference = saturate(depthDifference / _DepthMaxDistance);
               float4 waterColor = lerp(_ShallowColor, _DeepColor, waterDepthDifference);

               float foamDepthDifference = saturate(depthDifference / _FoamDistance);
               float surfaceNoiseCutoff = foamDepthDifference * _SurfaceNoiseCutoff;
               float surfaceNoise = tex2D(_NoiseTex, i.noiseUV) > surfaceNoiseCutoff ? 1 : 0;;

                return waterColor + surfaceNoise;
            }
            ENDCG
        }
    }
}
