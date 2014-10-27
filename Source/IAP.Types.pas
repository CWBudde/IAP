unit IAP.Types;

interface

uses
  Types;

type
  PIAPSingleDynArray = ^TSingleDynArray;
  PIAPDoubleDynArray = ^TDoubleDynArray;

  TIAPSingleFixedArray = array [0..0] of Single;
  PIAPSingleFixedArray = ^TIAPSingleFixedArray;
  TIAPDoubleFixedArray = array [0..0] of Double;
  PIAPDoubleFixedArray = ^TIAPDoubleFixedArray;

  TIAPArrayOfSingleDynArray = array of TSingleDynArray;
  PIAPArrayOfSingleDynArray = ^TIAPArrayOfSingleDynArray;
  TIAPArrayOfDoubleDynArray = array of TDoubleDynArray;
  PIAPArrayOfDoubleDynArray = ^TIAPArrayOfDoubleDynArray;

  TIAPArrayOfSingleFixedArray = array of PIAPSingleFixedArray;
  PIAPArrayOfSingleFixedArray = ^TIAPArrayOfSingleFixedArray;
  TIAPArrayOfDoubleFixedArray = array of PIAPDoubleFixedArray;
  PIAPArrayOfDoubleFixedArray = ^TIAPArrayOfDoubleFixedArray;

  TIAPSingleDynMatrix = TIAPArrayOfSingleDynArray;
  PIAPSingleDynMatrix = ^TIAPSingleDynMatrix;
  TIAPDoubleDynMatrix = TIAPArrayOfDoubleDynArray;
  PIAPDoubleDynMatrix = ^TIAPDoubleDynMatrix;

  TIAPSingleFixedMatrix = array [0..0, 0..0] of Single;
  PIAPSingleFixedMatrix = ^TIAPSingleFixedMatrix;
  TIAPDoubleFixedMatrix = array [0..0, 0..0] of Double;
  PIAPDoubleFixedMatrix = ^TIAPDoubleFixedMatrix;

  TIAPSingleFixedPointerArray = array [0..0] of PIAPSingleFixedArray;
  PIAPSingleFixedPointerArray = ^TIAPSingleFixedPointerArray;
  TIAPDoubleFixedPointerArray = array [0..0] of PIAPDoubleFixedArray;
  PIAPDoubleFixedPointerArray = ^TIAPDoubleFixedPointerArray;

  TIAP2SingleArray = array [0..1] of Single;
  PIAP2SingleArray = ^TIAP2SingleArray;
  TIAP2DoubleArray = array [0..1] of Double;
  PIAP2DoubleArray = ^TIAP2DoubleArray;

  TIAP3SingleArray = array [0..2] of Single;
  PIAP3SingleArray = ^TIAP3SingleArray;
  TIAP3DoubleArray = array [0..2] of Double;
  PIAP3DoubleArray = ^TIAP3DoubleArray;

  TIAP4SingleArray = array [0..3] of Single;
  PIAP4SingleArray = ^TIAP4SingleArray;
  TIAP4DoubleArray = array [0..3] of Double;
  PIAP4DoubleArray = ^TIAP4DoubleArray;

  TIAP6SingleArray = array [0..5] of Single;
  PIAP6SingleArray = ^TIAP6SingleArray;
  TIAP6DoubleArray = array [0..5] of Double;
  PIAP6DoubleArray = ^TIAP6DoubleArray;

  TIAP8SingleArray = array [0..7] of Single;
  PIAP8SingleArray = ^TIAP8SingleArray;
  TIAP8DoubleArray = array [0..7] of Double;
  PIAP8DoubleArray = ^TIAP8DoubleArray;

  TIAP16SingleArray = array [0..15] of Single;
  PIAP16SingleArray = ^TIAP16SingleArray;
  TIAP16DoubleArray = array [0..15] of Double;
  PIAP16DoubleArray = ^TIAP16DoubleArray;

  PIAP512SingleArray = ^TIAP1024SingleArray;
  TIAP512SingleArray = array[0..512] of Single;
  PIAP512DoubleArray = ^TIAP1024DoubleArray;
  TIAP512DoubleArray = array[0..512] of Double;

  PIAP1024SingleArray = ^TIAP1024SingleArray;
  TIAP1024SingleArray = array[0..1024] of Single;
  PIAP1024DoubleArray = ^TIAP1024DoubleArray;
  TIAP1024DoubleArray = array[0..1024] of Double;

  TIAPMinMaxSingle = record
    min : Single;
    max : Single;
  end;
  TIAPMinMaxDouble = record
    min : Double;
    max : Double;
  end;

  TChunkName = array [0..3] of AnsiChar;

  TStrArray = array of string;

implementation

end.
