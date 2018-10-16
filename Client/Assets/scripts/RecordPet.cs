using UnityEngine;
using System.Collections;
using System.Collections.Generic;

public class RecordPet
{
	public string	id;
	public byte[] 	skin;
	public string	skinId;
	public int		attack;
	public int		health;

	public Sprite GetSkin()
	{
		if (skin != null)
		{
			Texture2D tex = new Texture2D (150, 200, TextureFormat.ARGB32, false);
			tex.LoadImage (skin);
			tex.Apply ();

			return Sprite.Create (tex, new Rect (0, 0, tex.width, tex.height), Vector2.one * 0.5f);
		}

		List<Sprite> skins = MenuMain.Instance.skins;
		int skin_index = Mathf.Max(0, Mathf.Min(skins.Count - 1, int.Parse (skinId)));
		return skins [skin_index];
	}

	public void SetSkin(Sprite pic)
	{
		skin = pic.texture.EncodeToPNG ();
	}

	new public string ToString()
	{
		return "{id=" + id + ", attack=" + attack.ToString () + ", health=" + health.ToString () + ", skin=" + (skin != null ? skin.ToString() : "null") + "}";
	}
}
