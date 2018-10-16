using UnityEngine;
using UnityEngine.UI;
using System.Collections;

public class MenuLogin : MonoBehaviour
{
	public Text public_key;
	public Text private_key;

	void Start()
	{
	}

	public void OnLogin()
	{
		Debug.Log ("login");
		MenuMain.Instance.ShowMyPets ();
	}
}
