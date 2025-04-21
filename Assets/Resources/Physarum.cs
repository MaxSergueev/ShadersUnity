using UnityEngine;

public class PhysarumSimulation : MonoBehaviour
{
    // Compute shader reference
    public ComputeShader computeShader;

    // Rendering materials
    public Material renderMaterial;

    // Simulation parameters
    [Header("Simulation Settings")]
    public int width = 512;
    public int height = 512;
    public int numAgents = 100000;
    public float moveSpeed = 1.0f;
    public float turnSpeed = 1.0f;
    public float sensorAngle = 45.0f;
    public float sensorDistance = 3.0f;
    public float depositAmount = 5.0f;
    public float decayFactor = 0.9f;
    public float diffuseFactor = 0.1f;

    // Color gradient settings
    [Header("Visual Settings")]
    public Color backgroundColor = Color.black;
    public Gradient colorGradient;
    [Range(0, 10)]
    public float colorIntensity = 1.0f;

    // Internal buffers
    private RenderTexture trailMap;
    private ComputeBuffer agentsBuffer;
    private Color[] gradientColors;
    private ComputeBuffer colorBuffer;

    // Kernel IDs
    private int updateAgentsKernel;
    private int diffuseTrailsKernel;
    private int renderKernel;

    // Agent struct that will be passed to the compute shader
    struct Agent
    {
        public Vector2 position;
        public float angle;
    }

    void Start()
    {
        InitializeBuffers();
        InitializeAgents();
        SetupComputeShader();
    }

    void InitializeBuffers()
    {
        // Create trail map render texture
        trailMap = new RenderTexture(width, height, 0, RenderTextureFormat.ARGBFloat);
        trailMap.enableRandomWrite = true;
        trailMap.Create();

        // Create agents buffer
        agentsBuffer = new ComputeBuffer(numAgents, sizeof(float) * 3); // position x, y and angle

        // Generate color gradient buffer
        gradientColors = new Color[256];
        for (int i = 0; i < 256; i++)
        {
            float t = i / 255f;
            gradientColors[i] = colorGradient.Evaluate(t);
        }
        colorBuffer = new ComputeBuffer(256, sizeof(float) * 4); // RGBA color
        colorBuffer.SetData(gradientColors);
    }

    void InitializeAgents()
    {
        // Initialize agents
        Agent[] agents = new Agent[numAgents];
        
        
        Vector2 center = new Vector2(width / 2, height / 2);
        for (int i = 0; i < numAgents; i++)
        {
            // Calculate angle for even distribution around the circle
            float angle = (i / (float)numAgents) * 2 * Mathf.PI;

            // Create agent at center with angle pointing outward
            agents[i] = new Agent
            {
                position = center,
                angle = angle
            };

            // Slightly randomize positions around center
             float radius = Random.Range(0, 10);
            Vector2 offset = new Vector2(Mathf.Cos(angle), Mathf.Sin(angle)) * radius;
            agents[i].position = center + offset;
        }
        

        agentsBuffer.SetData(agents);
    }

    void SetupComputeShader()
    {
        // Get kernel IDs
        updateAgentsKernel = computeShader.FindKernel("UpdateAgents");
        diffuseTrailsKernel = computeShader.FindKernel("DiffuseTrails");
        renderKernel = computeShader.FindKernel("RenderTrails");

        // Set buffers
        computeShader.SetBuffer(updateAgentsKernel, "Agents", agentsBuffer);
        computeShader.SetTexture(updateAgentsKernel, "TrailMap", trailMap);

        computeShader.SetTexture(diffuseTrailsKernel, "TrailMap", trailMap);

        computeShader.SetTexture(renderKernel, "TrailMap", trailMap);
        computeShader.SetBuffer(renderKernel, "ColorGradient", colorBuffer);

        // Set simulation parameters
        UpdateShaderParameters();
    }

    void UpdateShaderParameters()
    {
        computeShader.SetInt("Width", width);
        computeShader.SetInt("Height", height);
        computeShader.SetFloat("MoveSpeed", moveSpeed);
        computeShader.SetFloat("TurnSpeed", turnSpeed);
        computeShader.SetFloat("SensorAngle", sensorAngle * Mathf.Deg2Rad);
        computeShader.SetFloat("SensorDistance", sensorDistance);
        computeShader.SetFloat("DepositAmount", depositAmount);
        computeShader.SetFloat("DecayFactor", decayFactor);
        computeShader.SetFloat("DiffuseFactor", diffuseFactor);
        computeShader.SetFloat("DeltaTime", Time.deltaTime);
        computeShader.SetFloat("ColorIntensity", colorIntensity);
        computeShader.SetVector("BackgroundColor", backgroundColor);
    }

    void Update()
    {
        // Update parameters when changed in the inspector
        UpdateShaderParameters();

        // Dispatch compute shader kernels
        int agentGroupSize = Mathf.CeilToInt(numAgents / 64.0f);
        computeShader.Dispatch(updateAgentsKernel, agentGroupSize, 1, 1);

        int textureGroupSizeX = Mathf.CeilToInt(width / 8.0f);
        int textureGroupSizeY = Mathf.CeilToInt(height / 8.0f);
        computeShader.Dispatch(diffuseTrailsKernel, textureGroupSizeX, textureGroupSizeY, 1);
        computeShader.Dispatch(renderKernel, textureGroupSizeX, textureGroupSizeY, 1);

        // Set the trail map to the material
        renderMaterial.mainTexture = trailMap;

        // Force a repaint of the scene view
        if (UnityEditor.SceneView.lastActiveSceneView != null)
            UnityEditor.SceneView.lastActiveSceneView.Repaint();

        // Request a repaint of the game view
        UnityEditorInternal.InternalEditorUtility.RepaintAllViews();
    }

    void OnDestroy()
    {
        if (agentsBuffer != null)
            agentsBuffer.Release();

        if (colorBuffer != null)
            colorBuffer.Release();

        if (trailMap != null)
            trailMap.Release();
    }
}
