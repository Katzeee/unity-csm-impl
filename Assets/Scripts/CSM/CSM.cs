using System;
using System.Collections;
using System.Collections.Generic;
using System.Linq;
using UnityEngine;

class LightFrustumData
{
    // light space
    public Vector3 MinPoint { get; set; }
    public Vector3 MaxPoint { get; set; }
    // world space
    public Vector3[] corners = new Vector3[8];
}

public class CSM : MonoBehaviour
{
    // Split count of view frustum
    [Range(1, 8)]
    public int splitCount = 4;

    // mix parameter of log split and uniform split
    [Range(0f, 1f)]
    public float mixParam = 0.5f;

    // Shadow map
    Matrix4x4[] world2ShadowMats;
    RenderTexture[] shadowMaps;
    private Camera lightCamera;
    public bool showViewFrustum = false;
    public bool showLightFrustum = false;

    // Start is called before the first frame update
    void Start()
    {

    }

    // Update is called once per frame
    void Update()
    {
        shadowMaps = new RenderTexture[splitCount];
        for (int i = 0; i < splitCount; i++)
        {
            shadowMaps[i] = new RenderTexture(1024, 1024, 24, UnityEngine.Experimental.Rendering.DefaultFormat.Shadow);
            Shader.SetGlobalTexture("_gShadowMapTexture" + i, shadowMaps[i]);
        }

        // create light camera
        if (lightCamera == null)
        {
            var lightCameraGO = new GameObject();
            lightCamera = lightCameraGO.AddComponent<Camera>();
            // lightCamera.cullingMask = 1 << La
            lightCamera.orthographic = true;
        }
        var splits = new float[splitCount + 1];
        splits[0] = Camera.main.nearClipPlane;
        for (int i = 1; i <= 1; i++)
        {
            splits[i] = GetTheNthSplit(Camera.main, i);
            // setup light camera
            var bounds = FrustumBoundingBox(Camera.main, splits[i - 1], splits[i], transform);
            Vector3 temp = Vector3.zero;
            for (i = 0; i < 4; i++)
            {
                temp += bounds.corners[i];
            }
            lightCamera.transform.position = temp / 4; // near plane center
            lightCamera.transform.rotation = transform.rotation;
            lightCamera.nearClipPlane = 0;
            lightCamera.farClipPlane = bounds.MaxPoint.z - bounds.MinPoint.z;
            lightCamera.aspect = (bounds.MaxPoint.x - bounds.MinPoint.x) / (bounds.MaxPoint.y - bounds.MinPoint.y);
            lightCamera.orthographicSize = (bounds.MaxPoint.y - bounds.MinPoint.y) / 2; // half of plane height
        }

    }

    float GetTheNthSplit(Camera camera, int i)
    {
        if (i < 0 || i > splitCount)
        {
            throw new ArgumentException("i");
        }
        var logSplit = camera.nearClipPlane * MathF.Pow(camera.farClipPlane / camera.nearClipPlane, i / splitCount);
        var uniformSplit = camera.nearClipPlane + (camera.farClipPlane - camera.nearClipPlane) * i / splitCount;
        return mixParam * logSplit + (1 - mixParam) * uniformSplit;
    }


    void FrustumCornerToWorldSpace(Camera camera, float z, Camera.MonoOrStereoscopicEye eye, Vector3[] corners)
    {
        // Local space
        camera.CalculateFrustumCorners(new Rect(0, 0, 1, 1), z, eye, corners);
        // To world space
        for (int i = 0; i < 4; i++)
        {
            corners[i] = camera.transform.TransformPoint(corners[i]);
        }
    }


    LightFrustumData FrustumBoundingBox(Camera camera, float nearPlane, float farplane, Transform light)
    {
        // near plane
        Vector3[] nearCorners = new Vector3[4];
        FrustumCornerToWorldSpace(camera, nearPlane, Camera.MonoOrStereoscopicEye.Mono, nearCorners);

        // far plane
        Vector3[] farCorners = new Vector3[4];
        FrustumCornerToWorldSpace(camera, farplane, Camera.MonoOrStereoscopicEye.Mono, farCorners);

        // calculate bounding box
        Vector3 minPoint = new();
        Vector3 maxPoint = new();
        // world to light space
        for (int i = 0; i < 4; i++)
        {
            nearCorners[i] = light.InverseTransformPoint(nearCorners[i]);
            farCorners[i] = light.InverseTransformPoint(farCorners[i]);
        }
        minPoint.x = Mathf.Min(nearCorners.Min((p) => p.x), farCorners.Min((p) => p.x));
        minPoint.y = Mathf.Min(nearCorners.Min((p) => p.y), farCorners.Min((p) => p.y));
        minPoint.z = Mathf.Min(nearCorners.Min((p) => p.z), farCorners.Min((p) => p.z));

        maxPoint.x = Mathf.Max(nearCorners.Max((p) => p.x), farCorners.Max((p) => p.x));
        maxPoint.y = Mathf.Max(nearCorners.Max((p) => p.y), farCorners.Max((p) => p.y));
        maxPoint.z = Mathf.Max(nearCorners.Max((p) => p.z), farCorners.Max((p) => p.z));

        LightFrustumData bounds = new();
        bounds.MinPoint = minPoint;
        bounds.MaxPoint = maxPoint;

        // HINT: two points can only describe a AABB, so we should record all 8 points
        bounds.corners[0] = new Vector3(minPoint.x, minPoint.y, minPoint.z);
        bounds.corners[1] = new Vector3(minPoint.x, maxPoint.y, minPoint.z);
        bounds.corners[2] = new Vector3(maxPoint.x, maxPoint.y, minPoint.z);
        bounds.corners[3] = new Vector3(maxPoint.x, minPoint.y, minPoint.z);
        bounds.corners[4] = new Vector3(minPoint.x, minPoint.y, maxPoint.z);
        bounds.corners[5] = new Vector3(minPoint.x, maxPoint.y, maxPoint.z);
        bounds.corners[6] = new Vector3(maxPoint.x, maxPoint.y, maxPoint.z);
        bounds.corners[7] = new Vector3(maxPoint.x, minPoint.y, maxPoint.z);

        // back to world space after get 8 points
        for (int i = 0; i < 8; i++)
        {
            bounds.corners[i] = light.TransformPoint(bounds.corners[i]);
        }

        return bounds;
    }


    // don't need start game
    void OnDrawGizmos()
    {
        var mainCam = Camera.main;
        Gizmos.color = Color.green;
        // https://discussions.unity.com/t/drawfrustum-is-drawing-incorrectly/518760/3
        // Gizmos.DrawFrustum(mainCam.transform.position, mainCam.fieldOfView, mainCam.farClipPlane, mainCam.nearClipPlane, mainCam.aspect); // incorrect
        if (showViewFrustum)
        {
            GizmosUtilities.DrawFrustum(mainCam);
        }

        var splits = new float[splitCount + 1];
        splits[0] = mainCam.nearClipPlane;
        for (int i = 1; i <= splitCount; i++)
        {
            splits[i] = GetTheNthSplit(mainCam, i);
            var bounds = FrustumBoundingBox(mainCam, splits[i - 1], splits[i], transform);
            var splitSquare = new Vector3[4];
            FrustumCornerToWorldSpace(mainCam, splits[i], Camera.MonoOrStereoscopicEye.Mono, splitSquare);
            if (showViewFrustum)
            {
                Gizmos.color = Color.green;
                GizmosUtilities.DrawWireSquare(splitSquare);
            }
            if (showLightFrustum)
            {
                Gizmos.color = Color.red;
                GizmosUtilities.DrawWireCube(bounds.corners);
            }
        }
    }

}
