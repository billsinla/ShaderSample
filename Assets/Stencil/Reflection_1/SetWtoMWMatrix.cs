using System.Collections;
using System.Collections.Generic;
using UnityEngine;

//Set World to Mirror World Matrix
public class SetWtoMWMatrix : MonoBehaviour
{
    //WtoMW_Object的transform;
    Transform refTransform;
    //”World“ To ”MirrorWorld“ Matrix（世界转换到镜子世界的矩阵）
    Matrix4x4 WtoMW;
    Material material;
    //Y轴对称反转矩阵
    Matrix4x4 YtoNegativeY = new Matrix4x4(
        new Vector4(1, 0, 0, 0),
        new Vector4(0, -1, 0, 0),
        new Vector4(0, 0, 1, 0),
        new Vector4(0, 0, 0, 1));

    private void Start()
    {
        material = GetComponent<MeshRenderer>().sharedMaterial;
        refTransform = GameObject.Find("WtoMW_Object").transform;

    }

    void Update()
    {
        WtoMW = refTransform.localToWorldMatrix * YtoNegativeY * refTransform.worldToLocalMatrix;
        material.SetMatrix("_WtoMW", WtoMW);
    }
}