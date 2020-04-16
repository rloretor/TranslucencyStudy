using UnityEngine;


[ExecuteInEditMode]
public class ViewDepthCommand : CommandRenderController
{
    readonly int DepthDiffId = Shader.PropertyToID("_DepthDifference");

    protected override void ConfigureDrawing()
    {
        var cam = Camera.current;
        var commandBuffer = _CommandBufferMap[cam];
        commandBuffer.GetTemporaryRT(DepthDiffId, -1, -1, 24, FilterMode.Bilinear, RenderTextureFormat.RGFloat);

        commandBuffer.SetRenderTarget(DepthDiffId);
        commandBuffer.ClearRenderTarget(true, true, new Color(0, 0, 0, 0));
        commandBuffer.DrawMesh(_mesh,
            Matrix4x4.TRS(MeshTransform.transform.position, MeshTransform.transform.rotation,
                MeshTransform.transform.localScale), _depthMaterial, 0, 2);

        commandBuffer.DrawMesh(_mesh,
            Matrix4x4.TRS(MeshTransform.transform.position, MeshTransform.transform.rotation,
                MeshTransform.transform.localScale), _depthMaterial, 0, 1);
    }

    /*
    public Shader DepthEstimatorShader;
    public Transform MeshTransform;
    public Mesh Mesh;

    private Material depthEstimatorMaterial;
    private readonly int DepthDiffId = Shader.PropertyToID("_DepthDifference");

    private Dictionary<Camera, CommandBuffer> customPipelinedCameras =
        new Dictionary<Camera, CommandBuffer>();


    public void OnWillRenderObject()
    {
        if (Mesh == null || Mesh != MeshTransform.GetComponent<MeshFilter>().sharedMesh)
        {
            Mesh = MeshTransform.GetComponent<MeshFilter>().sharedMesh;
        }

        var act = gameObject.activeInHierarchy && enabled;
        if (!act)
        {
            Cleanup();
            return;
        }

        Camera cam = Camera.current;
        if (cam == null)
        {
            return;
        }

        if (!depthEstimatorMaterial)
        {
            depthEstimatorMaterial = new Material(DepthEstimatorShader);
            depthEstimatorMaterial.hideFlags = HideFlags.HideAndDontSave;
        }

        CommandBuffer DepthCommand = null;
        if (!customPipelinedCameras.ContainsKey(cam))
        {
            DepthCommand = new CommandBuffer()
            {
                name = "DepthDifference"
            };

            customPipelinedCameras.Add(cam, DepthCommand);
            cam.AddCommandBuffer(CameraEvent.AfterForwardOpaque, DepthCommand);
        }
        else
        {
            DepthCommand = customPipelinedCameras[cam];
            DepthCommand.Clear();
        }

        DepthCommand.GetTemporaryRT(DepthDiffId, -1, -1, 24, FilterMode.Bilinear, RenderTextureFormat.RGFloat);

        DepthCommand.SetRenderTarget(DepthDiffId);
        DepthCommand.ClearRenderTarget(true, true, new Color(0, 0, 0, 0));
        DepthCommand.DrawMesh(Mesh,
            Matrix4x4.TRS(MeshTransform.transform.position, MeshTransform.transform.rotation,
                MeshTransform.transform.localScale), depthEstimatorMaterial, 0, 2);

        DepthCommand.DrawMesh(Mesh,
            Matrix4x4.TRS(MeshTransform.transform.position, MeshTransform.transform.rotation,
                MeshTransform.transform.localScale), depthEstimatorMaterial, 0, 1);
    }

    public void OnDisable()
    {
        Cleanup();
    }
    

    private void Cleanup()
    {
        foreach (var cam in customPipelinedCameras)
        {
            cam.Value.Clear();
            if (cam.Key == null)
            {
                continue;
            }

            cam.Key.RemoveAllCommandBuffers();
        }

        customPipelinedCameras.Clear();
        Object.DestroyImmediate(depthEstimatorMaterial);
    }
    */
}