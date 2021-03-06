(*
  * Copyright (c) 2009-2010, Ciobanu Alexandru
  * All rights reserved.
  *
  * Redistribution and use in source and binary forms, with or without
  * modification, are permitted provided that the following conditions are met:
  *     * Redistributions of source code must retain the above copyright
  *       notice, this list of conditions and the following disclaimer.
  *     * Redistributions in binary form must reproduce the above copyright
  *       notice, this list of conditions and the following disclaimer in the
  *       documentation and/or other materials provided with the distribution.
  *     * Neither the name of the <organization> nor the
  *       names of its contributors may be used to endorse or promote products
  *       derived from this software without specific prior written permission.
  *
  * THIS SOFTWARE IS PROVIDED BY THE AUTHOR ''AS IS'' AND ANY
  * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
  * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
  * DISCLAIMED. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY
  * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
  * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
  * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
  * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
  * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
  * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*)

{$I ../DeHL.Defines.inc}
unit DeHL.Collections.DistinctMultiMap;

interface

uses SysUtils,
	DeHL.Base,
	DeHL.Types,
	DeHL.Exceptions,
	DeHL.Arrays,
	DeHL.Serialization,
	DeHL.Collections.Base,
	DeHL.Collections.Abstract,
	DeHL.Collections.HashSet,
	DeHL.Collections.Dictionary;

type
	///<summary>The generic <c>multi map</c> collection.</summary>
	///<remarks>This type uses a <c>dictionary</c> and a number of <c>sets</c> to store its
	///keys and values.</remarks>
	TDistinctMultiMap<TKey, TValue> = class(TAbstractDistinctMultiMap<TKey, TValue>)
	private
		FInitialCapacity: NativeUInt;

	protected
		///<summary>Called when the map needs to initialize its internal dictionary.</summary>
		///<param name="AKeyType">The type object describing the keys.</param>
		///<remarks>This method creates a hash-based dictionary used as the underlying back-end for the map.</remarks>
		function CreateDictionary(const AKeyType: IType<TKey>): IDictionary<TKey, ISet<TValue>>; override;

		///<summary>Called when the map needs to initialize a set assoiated with a key.</summary>
		///<param name="AValueType">The type object describing the values.</param>
		///<remarks>This method creates a hash-based set. This set is associated with a key and store the map's
		///values for that key.</remarks>
		function CreateSet(const AValueType: IType<TValue>): ISet<TValue>; override;

		///<summary>Called when the serialization process is about to begin.</summary>
		///<param name="AData">The serialization data exposing the context and other serialization options.</param>
		procedure StartSerializing(const AData: TSerializationData); override;

		///<summary>Called when the deserialization process is about to begin.</summary>
		///<param name="AData">The deserialization data exposing the context and other deserialization options.</param>
		///<exception cref="DeHL.Exceptions|ESerializationException">Default implementation.</exception>
		procedure StartDeserializing(const AData: TDeserializationData); override;

		///<summary>Called when the an pair has been deserialized and needs to be inserted into the map.</summary>
		///<param name="AKey">The key that was deserialized.</param>
		///<param name="AValue">The value that was deserialized.</param>
		///<remarks>This method simply adds the element to the map.</remarks>
		procedure DeserializePair(const AKey: TKey; const AValue: TValue); override;
	public
		///<summary>Creates a new instance of this class.</summary>
		///<param name="AInitialCapacity">The map's initial capacity.</param>
		///<remarks>The default type object is requested.</remarks>
		constructor Create(const AInitialCapacity: NativeUInt); overload;

		///<summary>Creates a new instance of this class.</summary>
		///<param name="AKeyType">The type object describing the keys.</param>
		///<param name="AValueType">The type object describing the values.</param>
		///<param name="AInitialCapacity">The map's initial capacity.</param>
		///<exception cref="DeHL.Exceptions|ENilArgumentException"><paramref name="AKeyType"/> is <c>nil</c>.</exception>
		///<exception cref="DeHL.Exceptions|ENilArgumentException"><paramref name="AValueType"/> is <c>nil</c>.</exception>
		constructor Create(const AKeyType: IType<TKey>; const AValueType: IType<TValue>;
			const AInitialCapacity: NativeUInt); overload;
	end;

	///<summary>The generic <c>multi map</c> collection designed to store objects.</summary>
	///<remarks>This type uses a <c>dictionary</c> and a number of <c>sets</c> to store its
	///keys and values.</remarks>
	TObjectDistinctMultiMap<TKey, TValue> = class(TDistinctMultiMap<TKey, TValue>)
	private
		FKeyWrapperType  : TMaybeObjectWrapperType<TKey>;
		FValueWrapperType: TMaybeObjectWrapperType<TValue>;

		{ Getters/Setters for OwnsKeys }
		function GetOwnsKeys: Boolean;
		procedure SetOwnsKeys(const Value: Boolean);

		{ Getters/Setters for OwnsValues }
		function GetOwnsValues: Boolean;
		procedure SetOwnsValues(const Value: Boolean);

	protected
		///<summary>Installs the type objects describing the key and the value or the stored pairs.</summary>
		///<param name="AKeyType">The key's type object to install.</param>
		///<param name="AValueType">The value's type object to install.</param>
		///<remarks>This method installs a custom wrapper designed to suppress the cleanup of objects on request.
		///Make sure to call this method in descendant classes.</remarks>
		///<exception cref="DeHL.Exceptions|ENilArgumentException"><paramref name="AKeyType"/> is <c>nil</c>.</exception>
		///<exception cref="DeHL.Exceptions|ENilArgumentException"><paramref name="AValueType"/> is <c>nil</c>.</exception>
		procedure InstallTypes(const AKeyType: IType<TKey>; const AValueType: IType<TValue>); override;

	public
		///<summary>Specifies whether this map owns the keys.</summary>
		///<returns><c>True</c> if the map owns the keys; <c>False</c> otherwise.</returns>
		///<remarks>This property controls the way the map controls the life-time of the stored keys. The value of this property has effect only
		///if the keys are objects, otherwise it is ignored.</remarks>
		property OwnsKeys: Boolean read GetOwnsKeys write SetOwnsKeys;

		///<summary>Specifies whether this map owns the values.</summary>
		///<returns><c>True</c> if the map owns the values; <c>False</c> otherwise.</returns>
		///<remarks>This property controls the way the map controls the life-time of the stored values. The value of this property has effect only
		///if the values are objects, otherwise it is ignored.</remarks>
		property OwnsValues: Boolean read GetOwnsValues write SetOwnsValues;
	end;

implementation

const
	DefaultArrayLength = 32;

	{ TDistinctMultiMap<TKey, TValue> }

constructor TDistinctMultiMap<TKey, TValue>.Create(const AInitialCapacity: NativeUInt);
begin
	FInitialCapacity := AInitialCapacity;
	inherited Create();
end;

constructor TDistinctMultiMap<TKey, TValue>.Create(const AKeyType: IType<TKey>; const AValueType: IType<TValue>;
	const AInitialCapacity: NativeUInt);
begin
	FInitialCapacity := AInitialCapacity;
	inherited Create(AKeyType, AValueType);
end;

function TDistinctMultiMap<TKey, TValue>.CreateDictionary(const AKeyType: IType<TKey>): IDictionary<TKey, ISet<TValue>>;
var
	Cap: NativeUInt;
begin
	{ Create a simple dictionary }
	if FInitialCapacity = 0 then
		Cap := DefaultArrayLength
	else
		Cap := FInitialCapacity;

	Result := TDictionary < TKey, ISet < TValue >>.Create(AKeyType, TType < ISet < TValue >>.Default, Cap);
end;

function TDistinctMultiMap<TKey, TValue>.CreateSet(const AValueType: IType<TValue>): ISet<TValue>;
begin
	{ Create a simple list }
	Result := THashSet<TValue>.Create(AValueType);
end;

procedure TDistinctMultiMap<TKey, TValue>.DeserializePair(const AKey: TKey; const AValue: TValue);
begin
	{ Very simple }
	Add(AKey, AValue);
end;

procedure TDistinctMultiMap<TKey, TValue>.StartDeserializing(const AData: TDeserializationData);
begin
	{ Call the constructor in this instance to initialize myself first }
	//Create( DefaultArrayLength );

	Self.FInitialCapacity := DefaultArrayLength;
	inherited Create();
end;

procedure TDistinctMultiMap<TKey, TValue>.StartSerializing(const AData: TSerializationData);
begin
	//Do nothing, just say that I am here and I can be serialized
end;

{ TObjectDistinctMultiMap<TKey, TValue> }

procedure TObjectDistinctMultiMap<TKey, TValue>.InstallTypes(const AKeyType: IType<TKey>; const AValueType: IType<TValue>);
begin
	{ Create a wrapper over the real type class and switch it }
	FKeyWrapperType   := TMaybeObjectWrapperType<TKey>.Create(AKeyType);
	FValueWrapperType := TMaybeObjectWrapperType<TValue>.Create(AValueType);

	{ Install overridden type }
	inherited InstallTypes(FKeyWrapperType, FValueWrapperType);
end;

function TObjectDistinctMultiMap<TKey, TValue>.GetOwnsKeys: Boolean;
begin
	Result := FKeyWrapperType.AllowCleanup;
end;

function TObjectDistinctMultiMap<TKey, TValue>.GetOwnsValues: Boolean;
begin
	Result := FValueWrapperType.AllowCleanup;
end;

procedure TObjectDistinctMultiMap<TKey, TValue>.SetOwnsKeys(const Value: Boolean);
begin
	FKeyWrapperType.AllowCleanup := Value;
end;

procedure TObjectDistinctMultiMap<TKey, TValue>.SetOwnsValues(const Value: Boolean);
begin
	FValueWrapperType.AllowCleanup := Value;
end;

end.
