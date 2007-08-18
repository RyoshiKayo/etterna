/* BitmapText - An actor that holds a Font and draws text to the screen. */

#ifndef BITMAPTEXT_H
#define BITMAPTEXT_H

#include "Actor.h"
class RageTexture;

class Font;

class BitmapText : public Actor
{
public:
	BitmapText();
	BitmapText( const BitmapText &cpy );
	BitmapText &operator =( const BitmapText &cpy );
	virtual ~BitmapText();

	virtual void LoadFromNode( const XNode* pNode );
	virtual BitmapText *Copy() const;

	bool LoadFromFont( const RString& sFontName );
	bool LoadFromTextureAndChars( const RString& sTexturePath, const RString& sChars );
	virtual void SetText( const RString& sText, const RString& sAlternateText = "", int iWrapWidthPixels = -1 );
	void SetVertSpacing( int iSpacing );
	void SetMaxWidth( float fMaxWidth );
	void SetMaxHeight( float fMaxHeight );
	void SetWrapWidthPixels( int iWrapWidthPixels );
	void CropToWidth( int iWidthInSourcePixels );

	virtual bool EarlyAbortDraw() const;
	virtual void DrawPrimitives();

	void SetRainbowScroll( bool b )	{ m_bRainbowScroll = b; }
	void SetJitter( bool b )	{ m_bJitter = b; }

	void SetHorizAlign( float f );

	void GetLines( vector<wstring> &wTextLines ) { wTextLines = m_wTextLines; }

	RString GetText() const { return m_sText; }
	/* Return true if the string 's' will use an alternate string, if available. */
	bool StringWillUseAlternate( const RString& sText, const RString& sAlternateText ) const;

	//
	// Commands
	//
	virtual void PushSelf( lua_State *L );

protected:
	Font			*m_pFont;
	RString			m_sText;
	vector<wstring>		m_wTextLines;
	vector<int>		m_iLineWidths;		// in source pixels
	int			m_iWrapWidthPixels;	// -1 = no wrap
	float			m_fMaxWidth;
	float			m_fMaxHeight;
	bool			m_bRainbowScroll;
	bool			m_bJitter;
	int			m_iVertSpacing;

	vector<RageSpriteVertex>	m_aVertices;
	vector<RageTexture *>		m_pTextures;
	
	// recalculate the items in SetText()
	void BuildChars();
	void DrawChars();
	void UpdateBaseZoom();
};

#endif

/*
 * (c) 2001-2004 Chris Danford, Charles Lohr
 * All rights reserved.
 * 
 * Permission is hereby granted, free of charge, to any person obtaining a
 * copy of this software and associated documentation files (the
 * "Software"), to deal in the Software without restriction, including
 * without limitation the rights to use, copy, modify, merge, publish,
 * distribute, and/or sell copies of the Software, and to permit persons to
 * whom the Software is furnished to do so, provided that the above
 * copyright notice(s) and this permission notice appear in all copies of
 * the Software and that both the above copyright notice(s) and this
 * permission notice appear in supporting documentation.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
 * OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT OF
 * THIRD PARTY RIGHTS. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR HOLDERS
 * INCLUDED IN THIS NOTICE BE LIABLE FOR ANY CLAIM, OR ANY SPECIAL INDIRECT
 * OR CONSEQUENTIAL DAMAGES, OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS
 * OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR
 * OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR
 * PERFORMANCE OF THIS SOFTWARE.
 */
