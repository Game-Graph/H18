using UnityEngine;
using System.Collections;
using System.Collections.Generic;
using System.IO;
using Newtonsoft.Json;

public class Server : MonoBehaviour 
{
	static Server Instance;

	void Awake()
	{
		Instance = this;
	}

	static void SaveAccount(RecordAccount account)
	{
		string json = JsonConvert.SerializeObject (account);
		File.WriteAllText ("account", json);
	}

	public static void GetAccount(System.Action<RecordAccount> callback)
	{
		Instance.StartCoroutine (Instance.IEGetAccount (callback));
	}

	IEnumerator IEGetAccount(System.Action<RecordAccount> callback)
	{
		using (WWW www = new WWW ("http://localhost:8080/getaccount")) {
			yield return www;
			RecordAccount account = JsonConvert.DeserializeObject<RecordAccount>(www.text);
			Debug.Log (account != null ? account.ToString() : "NULL");
			callback (account);
		}
	}

	public static void CreatePet(System.Action<RecordAccount> callback)
	{
		Debug.Log ("create pet");
		Instance.StartCoroutine (Instance.IECreatePet (callback));
	}

	IEnumerator IECreatePet(System.Action<RecordAccount> callback)
	{
		using (WWW www = new WWW ("http://localhost:8080/createpet", new byte[]{1})) {
			yield return www;
			Debug.Log (www.error);
			Debug.Log (www.text);
			RecordAccount account = JsonConvert.DeserializeObject<RecordAccount>(www.text);
			Debug.Log (account != null ? account.ToString() : "NULL");
			callback (account);
		}
	}

	public static void DeletePet(string pet_id, System.Action<RecordAccount> callback)
	{
		Instance.StartCoroutine (Instance.IEDeletePet (pet_id, callback));
	}

	IEnumerator IEDeletePet(string pet_id, System.Action<RecordAccount> callback)
	{
		byte[] bytes = System.Text.Encoding.UTF8.GetBytes (pet_id);
		using (WWW www = new WWW ("http://localhost:8080/deletepet", bytes)) {
			yield return www;
			RecordAccount account = JsonConvert.DeserializeObject<RecordAccount>(www.text);
			Debug.Log (account != null ? account.ToString() : "NULL");
			callback (account);
		}
	}

	static RecordPet petEnemy;
	static RecordPet petMy;

	public static void GetEnemy(RecordPet pet, System.Action<RecordPet> callback)
	{
		Instance.StartCoroutine (Instance.IEGetEnemy (pet.id, callback));
	}

	IEnumerator IEGetEnemy(string pet_id, System.Action<RecordPet> callback)
	{
		byte[] bytes = System.Text.Encoding.UTF8.GetBytes (pet_id);
		using (WWW www = new WWW ("http://localhost:8080/getenemy", bytes)) {
			yield return www;
			RecordPet pet = JsonConvert.DeserializeObject<RecordPet>(www.text);
			Debug.Log (pet != null ? pet.ToString() : "NULL");
			callback (pet);
		}
	}
		
	public static void Attack(int attack_type, int protect_type, System.Action<RecordFightStep> callback)
	{
		RecordAttack attack = new RecordAttack { attackType = attack_type, protectType = protect_type };
		Instance.StartCoroutine(Instance.IEAttack(attack, callback));
	}

	IEnumerator IEAttack(RecordAttack attack, System.Action<RecordFightStep> callback)
	{
		string json = JsonConvert.SerializeObject (attack);
		byte[] bytes = System.Text.Encoding.UTF8.GetBytes (json);
		using (WWW www = new WWW ("http://localhost:8080/attack", bytes)) {
			yield return www;
			RecordFightStep step = JsonConvert.DeserializeObject<RecordFightStep>(www.text);
			Debug.Log (step != null ? step.ToString() : "NULL");
			callback (step);
		}
	}

	public static void Giveup(System.Action<RecordFightStep> callback)
	{
		Instance.StartCoroutine (Instance.IEGiveup (callback));
	}

	IEnumerator IEGiveup(System.Action<RecordFightStep> callback)
	{
		using (WWW www = new WWW ("http://localhost:8080/giveup")) {
			yield return www;
			RecordFightStep step = JsonConvert.DeserializeObject<RecordFightStep>(www.text);
			Debug.Log (step != null ? step.ToString() : "NULL");
			callback (step);
		}
	}
}
