using UnityEngine;
using UnityEngine.Rendering;

[ExecuteInEditMode]
public class LightDepthCommand : CommandRenderController
{
    public Light _MainLight;
    [Range(0, 10)] public float _Bias;
    [Range(0, 10)] public float _DiskWidth;

    private readonly int DepthDiffId = Shader.PropertyToID("_LightDepth");
    private readonly int LightVMatrixId = Shader.PropertyToID("_lightV");
    private readonly int Bias = Shader.PropertyToID("_Bias");
    private readonly int DiskWidth = Shader.PropertyToID("_DiskWidth");


    protected override void ConfigureDrawing()
    {
        var cam = Camera.current;
        var commandBuffer = _CommandBufferMap[cam];

        commandBuffer.GetTemporaryRT(DepthDiffId, Screen.width, Screen.height, 4, FilterMode.Point,
            RenderTextureFormat.RFloat);
        commandBuffer.SetRenderTarget(DepthDiffId);
        commandBuffer.ClearRenderTarget(true, true, new Color(0, 0, 0, 0));
        commandBuffer.SetGlobalFloat(Bias, _Bias);
        commandBuffer.SetGlobalFloat(DiskWidth, _DiskWidth);
        commandBuffer.SetGlobalFloat(DiskWidth, _DiskWidth);


        SetLightVAndVPMatrix(cam, commandBuffer);
        commandBuffer.DrawMesh(_mesh,
            Matrix4x4.TRS(MeshTransform.transform.position, MeshTransform.transform.rotation,
                MeshTransform.transform.localScale), _depthMaterial, 0, 0);

        commandBuffer.SetRenderTarget(BuiltinRenderTextureType.None);
    }

    //https://answers.unity.com/questions/12713/how-do-i-reproduce-the-mvp-matrix.html
    private void SetLightVAndVPMatrix(Camera camera, CommandBuffer buffer)
    {
        bool d3d = SystemInfo.graphicsDeviceVersion.IndexOf("Direct3D") > -1;
        var V = _MainLight.transform.worldToLocalMatrix;

        if (d3d)
        {
            // Invert XY for rendering to a render texture
            for (int i = 0; i < 4; i++)
            {
                V[2, i] = -V[2, i];
            }
        }

        buffer.SetGlobalMatrix(LightVMatrixId, V);
    }
}