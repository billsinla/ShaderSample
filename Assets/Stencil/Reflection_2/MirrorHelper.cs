using System.Collections;
using System.Collections.Generic;
using UnityEngine;
 
public class MirrorHelper : MonoBehaviour
{
    public GameObject plane;
    public Material mat;
 
    void Start()
    {
        mat.SetVector("planeNormal", plane.transform.up);
        mat.SetVector("planePos", plane.transform.position);
    }
 
    void Update()
    {
        mat.SetVector("planeNormal", plane.transform.up);
        mat.SetVector("planePos", plane.transform.position);
    }
}