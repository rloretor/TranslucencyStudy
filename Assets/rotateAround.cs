using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class rotateAround : MonoBehaviour
{
    // Update is called once per frame
    void Update()
    {
        this.transform.Rotate(90 * Time.deltaTime, Random.Range(0, Time.deltaTime),
            Random.Range(0, Time.deltaTime));
    }
}