using System;
using UnityEngine;

/// <summary>
/// Helper functions for drawing Gizmos
/// </summary>
partial class GizmosUtilities
{
    public static void DrawFrustum(Camera cam)
    {
        Vector3[] nearCorners = new Vector3[4]; //Approx'd nearplane corners
        Vector3[] farCorners = new Vector3[4]; //Approx'd farplane corners
        Plane[] camPlanes = GeometryUtility.CalculateFrustumPlanes(cam); //get planes from matrix
        Plane temp = camPlanes[1]; camPlanes[1] = camPlanes[2]; camPlanes[2] = temp; //swap [1] and [2] so the order is better for the loop

        for (int i = 0; i < 4; i++)
        {
            nearCorners[i] = Plane3Intersect(camPlanes[4], camPlanes[i], camPlanes[(i + 1) % 4]); //near corners on the created projection matrix
            farCorners[i] = Plane3Intersect(camPlanes[5], camPlanes[i], camPlanes[(i + 1) % 4]); //far corners on the created projection matrix
        }

        for (int i = 0; i < 4; i++)
        {
            Debug.DrawLine(nearCorners[i], nearCorners[(i + 1) % 4], Color.green, Time.deltaTime, true); //near corners on the created projection matrix
            Debug.DrawLine(farCorners[i], farCorners[(i + 1) % 4], Color.green, Time.deltaTime, true); //far corners on the created projection matrix
            Debug.DrawLine(nearCorners[i], farCorners[i], Color.green, Time.deltaTime, true); //sides of the created projection matrix
        }
    }

    public static void DrawWireSquare(Vector3[] square)
    {
        if (square.Length < 4)
        {
            throw new ArgumentNullException("square");
        }
        for (int i = 0; i < 4; i++)
        {
            Gizmos.DrawLine(square[i], square[(i + 1) % 4]);
        }
    }

    public static void DrawWireCube(Vector3[] cube)
    {
        if (cube.Length < 8)
        {
            throw new ArgumentNullException("cube");
        }
        for (int i = 0; i < 4; i++)
        {
            Gizmos.DrawLine(cube[i], cube[(i + 1) % 4]);
            Gizmos.DrawLine(cube[4 + i], cube[4 + (i + 1) % 4]);
            Gizmos.DrawLine(cube[i], cube[4 + i]);
        }
    }

    private static Vector3 Plane3Intersect(Plane p1, Plane p2, Plane p3)
    { //get the intersection point of 3 planes
        return ((-p1.distance * Vector3.Cross(p2.normal, p3.normal)) +
                (-p2.distance * Vector3.Cross(p3.normal, p1.normal)) +
                (-p3.distance * Vector3.Cross(p1.normal, p2.normal))) /
            (Vector3.Dot(p1.normal, Vector3.Cross(p2.normal, p3.normal)));
    }

}