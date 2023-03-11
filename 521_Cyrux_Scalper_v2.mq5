
//+------------------------------------------------------------------+
//|                                                   SimpleRSIx.mq5 |
//|                                Copyright 2022, 521StealthAcadem! |
//|                                   https://t.me/+rr0GLGdADoAxMGFk |
//                                                https://t.me/Orims |
//+------------------------------------------------------------------+
#property copyright "https://t.me/Orims"
#property copyright      "https://t.me/Orims"
#property version   "1.00"

#include <Trade\Trade.mqh>
CTrade trade;

#define BtnClose "ButtonClose"
#define KEY_B 66
#define KEY_S 83
double lastPrice;

input group "==== Lots ===="
input double      Lots = 0;  //Lot Size
input int         TP = 0;
input int         SL = 0;

input group "==== Trail/TP Settings ===="
input ENUM_TIMEFRAMES Timeframes = PERIOD_CURRENT;
input double Step = 0.01;
input double Maximum = 0.2;


input group ""
input group "==== Volume Limits ===="
input group "EURUSD     || MIN: 0.1"
input group "V10 Lot    || MIN: 0.3 || MAX : 100 [SL:4500  TP: 30000 ]"
input group "V25 Lot    || MIN: 0.5 || MAX : 100 [SL:4500   TP: 30000 ]"
input group "V50 Lot    || MIN: 3 || MAX : 1000 [SL: 4500  TP: 30000 ]"
input group "V75 Lot    || MIN: 0.001 || MAX : 1 [SL: 400000  TP:3000000 ]"
input group "B1K Lot    || MIN: 0.2 || MAX : 1 [SL: 400000  TP:3000000 ]"
input group "V100 Lot   || MIN: 0.2 || MAX : 50 [SL:4500   TP:30000 ]"
input group "STEP Lot   || MIN: 0.1 || MAX : 20 [SL:45  TP: 300 ]"

input group ""
input group "AUTO TRADING ALLOWED"
//input bool IsSell_Only = true;
//input bool IsBuy_Only = true;
input bool Trade_Continuation = true;
input bool Trade_RiskEntry = true;

input group ""
input group "Trailing | BreakEven"
input bool        IsTrailingTypeR = true;
input bool        IsTrailingTypeA = true;
input bool        BreakEven = true;
input int BeTriggerPoints = 250;
input int BeBufferPoints = 25;

static double lastBid;
int barsTotalD1;
int TotalBars;

double ask = SymbolInfoDouble(_Symbol,SYMBOL_ASK);
//ask = NormalizeDouble(ask,_Digits);
double bid = SymbolInfoDouble(_Symbol,SYMBOL_BID);
//bid = NormalizeDouble(bid,_Digits);
double tpBuy   =  NormalizeDouble(ask + TP * _Point,_Digits);
double tpSell  =  NormalizeDouble(bid - TP * _Point,_Digits);
double slBuy   =  NormalizeDouble(ask - SL * _Point,_Digits);
double slSell  =  NormalizeDouble(bid + SL * _Point,_Digits);

ulong posTicket;
input int MagicNum = 345;

int StochHandle;
int rsiHandle;
int rsiHandle_M15;
int PSARHandle;
int MacdHandle;

int OnInit() {

      PSARHandle = iSAR(_Symbol,Timeframes,Step,Maximum);
      rsiHandle_M15 = iRSI(_Symbol, PERIOD_H1,14,PRICE_CLOSE);
      StochHandle = iStochastic(_Symbol,PERIOD_M15,14,3,3,MODE_SMA,STO_LOWHIGH);
      MacdHandle = iMACD(_Symbol,PERIOD_H1,12,26,9,PRICE_CLOSE);
      
      
      createButton(BtnClose,"CAP",5,80,45,25,clrWhite,clrRed);//button to close all trades at once
      CreateButtonPause();
     
      trade.SetExpertMagicNumber(MagicNum);  
      TotalBars  =  iBars(_Symbol,PERIOD_H1);
      lastBid  =  SymbolInfoDouble(_Symbol,SYMBOL_BID);

      return(INIT_SUCCEEDED);
}


void OnDeinit(const int reason)  {

      ObjectDelete(0,BtnClose);
      ObjectDelete (0, ButtonName);
      //ObjectDelete(0, createObj());
   	Comment("");
      ChartRedraw();
   
}

void OnTick()  {
      int barsD1   =  iBars(_Symbol,PERIOD_D1);
      if(barsTotalD1 != barsD1)  {
         barsTotalD1 =  barsD1;
      Print(__FUNCTION__," > Reset"); 
      }

      double psar[];     
      CopyBuffer(PSARHandle,0,0,2,psar);
      
      double rsi_H1[];
      CopyBuffer(rsiHandle_M15,0,1,1,rsi_H1);
      
      double stoch_H1[];
      CopyBuffer(StochHandle,0,1,1,stoch_H1);
      
      double macdsignal_H1[];
      CopyBuffer(MacdHandle,SIGNAL_LINE,1,2,macdsignal_H1);
      
      double macdHisto_H1[];
      CopyBuffer(MacdHandle,MAIN_LINE,1,2,macdHisto_H1);
         
      double   highD1  =  iHigh(_Symbol,PERIOD_D1,1);
      double   lowD1   =  iLow(_Symbol,PERIOD_D1,1);
      double   highD2  =  iHigh(_Symbol,PERIOD_D1,2);
      double   lowD2   =  iLow(_Symbol,PERIOD_D1,2);
      
      ask = SymbolInfoDouble(_Symbol,SYMBOL_ASK);
      //ask = NormalizeDouble(ask,_Digits);
      bid = SymbolInfoDouble(_Symbol,SYMBOL_BID);
      //bid = NormalizeDouble(bid,_Digits);
      tpBuy   =  NormalizeDouble(ask + TP * _Point,_Digits);
      tpSell  =  NormalizeDouble(bid - TP * _Point,_Digits);
      slBuy   =  NormalizeDouble(ask - SL * _Point,_Digits);
      slSell  =  NormalizeDouble(bid + SL * _Point,_Digits);
            
      //if (!ButtonState) return;
      int bars = iBars(_Symbol,PERIOD_H1);
      if (TotalBars != bars){
      int HLCC = getHlcSignal();
      //int HLCC2 = getHlcSignal2();
      
           if (Trade_Continuation){
            if (macdsignal_H1 [0] < 0 ){// && macdHisto_H1 [0] < 0 ){
               if (stoch_H1[0] >= 70){
                  if (HLCC > 0){  //&& bid >= highD1){
                  
                     int highBar = iHighest(_Symbol, PERIOD_H1, MODE_HIGH,2,0);
                     double slS = iHigh (_Symbol, PERIOD_H1,highBar);
                     datetime time  =  iTime(_Symbol,PERIOD_H1,1);
                     
                     //if (IsSell_Only){
                     trade.Sell(Lots,_Symbol,bid,(slS + SL *_Point),tpSell, "Continuation");
                     createObj(time,highBar,221,-1,clrRed,"..");
                     TotalBars = bars;
                     //}
                     
                     Print(" %s Sell (Continuation) ", Symbol());
                     Alert ("");
                     Alert(StringFormat(" %s Sell (Continuation) ", Symbol()));
                     SendNotification(StringFormat(" %s Sell (Continuation)", Symbol()));
                  
                  }
             }
            
            }else if (macdsignal_H1 [0] > 0 ){//&& macdHisto_H1 [0] > 0){
               if (stoch_H1[0] <= 30){
                  if (HLCC < 0){//  && ask <= lowD1){
                  
                     int lowBar = iLowest(_Symbol, PERIOD_H1, MODE_LOW,2,0);
                     double slB = iLow (_Symbol, PERIOD_H1,lowBar);
                     datetime time  =  iTime(_Symbol,PERIOD_H1,1);
                     
                     //if (IsBuy_Only){
                     trade.Buy(Lots,_Symbol,ask,(slB - SL * _Point) ,tpBuy,"Continuation");
                     createObj(time,lowBar,221,1,clrBlue,"..");
                     TotalBars = bars;
                     //}
                       Print(" %s Buy (Continuation) ", Symbol());
                       Alert ("");
                       Alert(StringFormat(" %s Buy (Continuation) ", Symbol()));
                       SendNotification(StringFormat(" %s Buy (Continuation) ", Symbol()));
                  
                  }TotalBars = bars;
               
               }
             }
            } 
       

       if (Trade_RiskEntry){
             if (rsi_H1 [0] >= 60 && rsi_H1 [0] < 70 && macdsignal_H1 [0] > 0){
               if (HLCC > 0){
             
                  int highBar = iHighest(_Symbol, PERIOD_H1, MODE_HIGH,2,0);
                  double slS = iHigh (_Symbol, PERIOD_H1,highBar);
                  datetime time  =  iTime(_Symbol,PERIOD_H1,1);
                  
                  //if (IsSell_Only){
                  trade.Sell(Lots,_Symbol,bid,(slS + SL *_Point),tpSell, "RiskEntry");
                  //createObj(time,highBar,221,-1,clrRed,"..");
                  TotalBars = bars;
                  //}
                
                  Print(" %s SELL (RiskEntry) ", Symbol());
                  Alert ("");
                  Alert(StringFormat(" %s SELL (RiskEntry) ", Symbol()));
                  SendNotification(StringFormat(" %s SELL (RiskEntry) ", Symbol()));
                  TotalBars = bars;
               }
             
             }else if (rsi_H1 [0] > 30 && rsi_H1 [0] <= 40  && macdsignal_H1 [0] < 0){
               if (HLCC < 0){
             
                  int lowBar = iLowest(_Symbol, PERIOD_H1, MODE_LOW,2,0);
                  double slB = iLow (_Symbol, PERIOD_H1,lowBar);
                  datetime time  =  iTime(_Symbol,PERIOD_H1,1);
                  
                  //if (IsBuy_Only){
                  trade.Buy(Lots,_Symbol,ask,(slB - SL * _Point) ,tpBuy, "RiskEntry");
                  //createObj(time,lowBar,221,1,clrBlue,"..");
                  TotalBars = bars;
                  //}
                
                  Print(" %s BUY (RiskEntry) ", Symbol());
                  Alert ("");
                  Alert(StringFormat(" %s BUY (RiskEntry) ", Symbol()));
                  SendNotification(StringFormat(" %s BUY (RiskEntry) ", Symbol()));
                  TotalBars = bars;
               }
             }
           }
       
       }

   
          ////// Parabolic SAR trailing/////
             int lowBar = iLowest(_Symbol, PERIOD_H4, MODE_LOW,2,0);
             double slB = iLow (_Symbol, PERIOD_H4,lowBar);     
             int highBar = iHighest(_Symbol, PERIOD_H4, MODE_HIGH,2,0);
             double slS = iHigh (_Symbol, PERIOD_H4,highBar);
               
               ////Trailing stop  
               if (IsTrailingTypeR){   
                  double Sl = psar[1];
                  Sl = NormalizeDouble(Sl,_Digits);
                  for(int i = PositionsTotal()-1; i >= 0; i--){
                     posTicket = PositionGetTicket(i);
                     if(PositionSelectByTicket(posTicket)){
                        if(PositionGetString(POSITION_SYMBOL) == _Symbol && PositionGetInteger(POSITION_MAGIC) == MagicNum){
                           ENUM_POSITION_TYPE posType = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
                           
                           double posSl = PositionGetDouble(POSITION_SL);
                           double posTp = PositionGetDouble(POSITION_TP);
                           
                           if(posType == POSITION_TYPE_BUY){
                              if(Sl > posSl || posSl == 0){
                                 if(trade.PositionModify(posTicket,Sl,posTp)){
                                    Print (__FUNCTION__, " > Pos #", posTicket," modified by trailing stop");  
                                 }
                              }
                           }else if(posType == POSITION_TYPE_SELL){
                              if(Sl < posSl || posSl == 0){
                                 if(trade.PositionModify(posTicket,Sl,posTp)){
                                    Print (__FUNCTION__, " > Pos #", posTicket," modified by trailing stop");  
                                 }
                              }
                           }
                        }
                     }
                  }
                }
                
         
         //// Trailing type 2
         if (IsTrailingTypeA){/// Tight and agressive trailing stop... gets out too early, on first pull backs
            for (int i = PositionsTotal()-1; i >= 0; i--)   {
               posTicket = PositionGetTicket(i);
               CPositionInfo  pos;
               if(pos.SelectByTicket(posTicket))  {
                  if(pos.PositionType() == POSITION_TYPE_BUY)  {
                     if(slBuy > pos.StopLoss())   {
                        trade.PositionModify(posTicket,slB,pos.TakeProfit());
                     }
                  }else if (pos.PositionType() == POSITION_TYPE_SELL)   {
               
                     if(slSell < pos.StopLoss())   {
                     trade.PositionModify(posTicket,slS,pos.TakeProfit());
                     }
                  }
               }
            }
         }    
         //}
         
         ////////////////////////////////////////// BReak EVEN ////////////////
               
               ////Trailing stop  
               if (BreakEven){   
                  //double Sl = psar[1];
                  highBar = iHighest(_Symbol, PERIOD_H1, MODE_HIGH,2,0);
                  slS = iHigh (_Symbol, PERIOD_H1,highBar);
                  
                  lowBar = iLowest(_Symbol, PERIOD_H1, MODE_LOW,2,0);
                  slB = iLow (_Symbol, PERIOD_H1,lowBar); 
                     
                  slB = NormalizeDouble(slB,_Digits);
                  slS = NormalizeDouble(slS,_Digits);
                  for(int i = PositionsTotal()-1; i >= 0; i--){
                     posTicket = PositionGetTicket(i);
                     if(PositionSelectByTicket(posTicket)){
                        if(PositionGetString(POSITION_SYMBOL) == _Symbol && PositionGetInteger(POSITION_MAGIC) == MagicNum){
                           ENUM_POSITION_TYPE posType = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
                           
                           double posOpenPrice = PositionGetDouble(POSITION_PRICE_OPEN);
                           double posVolume = PositionGetDouble(POSITION_VOLUME);
                           double posSl = PositionGetDouble(POSITION_SL);
                           double posTp = PositionGetDouble(POSITION_TP);
                           
                           
                           if(posType == POSITION_TYPE_BUY){
                              if(bid > posOpenPrice + BeTriggerPoints * _Point){
                                 slB = posOpenPrice + BeBufferPoints * _Point;
                                 if( slB > posSl){
                                    if(trade.PositionModify(posTicket, slB,posTp)){
                                    Print (__FUNCTION__, " > Pos #", posTicket," modified by BE");  
                                    }
                                 }
                              }
                           }else if(posType == POSITION_TYPE_SELL){
                              if(bid < posOpenPrice - BeTriggerPoints * _Point){
                                 slS = posOpenPrice - BeBufferPoints * _Point;
                                 if(slS < posSl){
                                    if(trade.PositionModify(posTicket,slS,posTp)){
                                    Print (__FUNCTION__, " > Pos #", posTicket," modified by BE");  
                                    }
                                 }
                              }  
                              }
                              }
                           }
                        }
                     }
                  //}
                //}
         
         
         
         
         ///////////////////////////////////////////////////////////////////////
            
}      

int getHlcSignal()   {
         datetime time  =  iTime(_Symbol,PERIOD_H1,1);
         
         double   high1  =  iHigh(_Symbol,PERIOD_H1,1);
         double   low1   =  iLow(_Symbol,PERIOD_H1,1);
         double   open1  =  iOpen(_Symbol,PERIOD_H1,1);
         double   close1 =  iClose(_Symbol,PERIOD_H1,1);
      
         double   high2  =  iHigh(_Symbol,PERIOD_H1,2);
         double   low2  =  iLow(_Symbol,PERIOD_H1,2);
         double   open2  =  iOpen(_Symbol,PERIOD_H1,2);
         double   close2 =  iClose(_Symbol,PERIOD_H1,2);
  
         if(close1 > high2 && high1 > high2){  
       
            createObj(time,low1,221,1,clrNONE,"BC Candle");
            //Print("  --- Buy Commitment--- ", Symbol());
            //Alert ("");
            //Alert(StringFormat("  --- Buy Commitment--- ", Symbol()));
            //SendNotification(StringFormat(" --- Buy Commitment--- ", Symbol()));
         
            return 1;    
         }
         
         if(close1 < low2 && low1 < low2){  
      
            createObj(time,high1,222,-1,clrNONE,"SC Candle");
            //Print(" %s --- Sell Commitment--- ", Symbol());
            //Alert ("");
            //Alert(StringFormat(" %s --- Sell Commitment--- ", Symbol()));
           // SendNotification(StringFormat(" %s --- Sell Commitment--- ", Symbol()));
         
            return -1;  
           
         }return 0; //No pattern found
} 

void  OnChartEvent(
   const int       id,       // event ID
   const long&     lparam,   // long type event parameter
   const double&   dparam,   // double type event parameter
   const string&   sparam    // string type event parameter
)  {

   
   if(id == CHARTEVENT_MOUSE_MOVE){
      int cord_X = (int) lparam;
      int cord_Y = (int) dparam;
      
      int subWindow;
      datetime time;
      ChartXYToTimePrice(0,cord_X,cord_Y,subWindow,time,lastPrice);
      lastPrice = NormalizeDouble(lastPrice,_Digits);
      
      //Print(lastPrice," ", time);
      
   }


   if(id == CHARTEVENT_KEYDOWN){
      if (lparam == KEY_B ){// key B= 66, Key S = 83
         Print("B was pressed");
         if (lastPrice < SymbolInfoDouble(_Symbol,SYMBOL_ASK)){
         
            int lowBar = iLowest(_Symbol, PERIOD_H4, MODE_LOW,2,0);
            double slB = iLow (_Symbol, PERIOD_H4, lowBar);//iLow(_Symbol,PERIOD_CURRENT,0);
           
         
            trade.BuyLimit(Lots,lastPrice,_Symbol,slB);//,_Symbol,slBuy,0,ORDER_TIME_DAY,0," ");
         }
         
         
      }else if (lparam == KEY_S ){// key B= 66, Key S = 83
            Print("S was pressed");
               if (lastPrice > SymbolInfoDouble(_Symbol,SYMBOL_BID)){
               
                  int highBar = iHighest(_Symbol, PERIOD_H4, MODE_HIGH,2,0);
                  double slS = iHigh(_Symbol, PERIOD_H4, highBar);
                
                trade.SellLimit(Lots,lastPrice,_Symbol,slS);//,_Symbol,slSell,0,ORDER_TIME_DAY,0," ");
         }
      }
   }




   if(id == CHARTEVENT_OBJECT_CLICK)   {
      //Print("The ",sparam, "was clicked");
      if(sparam == BtnClose)  {
         for(int i = PositionsTotal()-1; i >= 0; i--) {
            posTicket = PositionGetTicket(i);
            if(trade.PositionClose(_Symbol)) {  //CAP per symbol only, not for the entire platform 
               Print("Position #",posTicket,"was closed...");
            }

         }
         ObjectSetInteger(0,BtnClose,OBJPROP_STATE,false);

      
      }

   }  else if(sparam != ButtonName) return;
	      if (id != CHARTEVENT_OBJECT_CLICK) return;
	
	      SetButtonState(ObjectGetInteger(0, ButtonName, OBJPROP_STATE, 0));

      
}


void  createObj(datetime time, double price, int arrowCode, int direction, color clr, string txt){
   string objName =  "";
   
   StringConcatenate(objName,"Signal@",time,"at",DoubleToString(price,_Digits),"(",arrowCode,")");
   if(ObjectCreate(0,objName,OBJ_ARROW,0,time,price)){
      ObjectSetInteger(0,objName,OBJPROP_ARROWCODE,arrowCode);
      ObjectSetInteger(0,objName,OBJPROP_COLOR,clr);
      if (direction > 0) ObjectSetInteger(0,objName,OBJPROP_ANCHOR,ANCHOR_TOP);
      if (direction < 0) ObjectSetInteger(0,objName,OBJPROP_ANCHOR,ANCHOR_BOTTOM);
      
   }
   string objNameDesc = objName+txt;
   if (ObjectCreate(0,objNameDesc,OBJ_ARROW,0,time,price)){
      ObjectSetString(0,objNameDesc,OBJPROP_TEXT," "+txt);
      ObjectSetInteger(0,objNameDesc,OBJPROP_COLOR,clrRed);
      if (direction > 0) ObjectSetInteger(0,objNameDesc,OBJPROP_ANCHOR,ANCHOR_TOP);
      if (direction < 0) ObjectSetInteger(0,objNameDesc,OBJPROP_ANCHOR,ANCHOR_BOTTOM);
   }

}

//Create CLOSE ALL Button
bool createButton(string objName, string text, int x, int y, int width, int height, color clrTxt, color clrBg) {

   ResetLastError();
   if(!ObjectCreate(0,objName,OBJ_BUTTON,0,0,0))   {
      Print(__FUNCTION__,": failed to create the button! Error code = ",GetLastError());
      return(false);
   }

   ObjectSetInteger(0,objName,OBJPROP_XDISTANCE,x);
   ObjectSetInteger(0,objName,OBJPROP_YDISTANCE,y);
   ObjectSetInteger(0,objName,OBJPROP_XSIZE,width);
   ObjectSetInteger(0,objName,OBJPROP_YSIZE,height);
   ObjectSetInteger(0,objName,OBJPROP_CORNER,CORNER_LEFT_UPPER);
   ObjectSetString(0,objName,OBJPROP_TEXT,text);
   ObjectSetInteger(0,objName,OBJPROP_FONTSIZE,12);
   ObjectSetInteger(0,objName,OBJPROP_COLOR,clrTxt);
   ObjectSetInteger(0,objName,OBJPROP_BGCOLOR,clrBg);
   ObjectSetInteger(0,objName,OBJPROP_BACK,true);
   ObjectSetInteger(0,objName,OBJPROP_STATE,false);
   ObjectSetInteger(0,objName,OBJPROP_SELECTABLE,false);
   ObjectSetInteger(0,objName,OBJPROP_SELECTED,false);
   return(true);

}


//Create Pause EA button
bool 		ButtonState = true; // Button state- running or paused state

const string ButtonName = "BUTTON_PAUSE";
const int ButtonXPosition = 85;
const int ButtonYPosition = 20;
const int ButtonWidth = 80;
const int ButtonHeight = 25;
const int ButtonCorner = CORNER_RIGHT_UPPER;
const string ButtonFont = "Arial Bold";
const int ButtonFontSize = 10;
const int ButtonTextColour = clrBlack;

//when running
const string ButtonTextRunning = "Running";
const int ButtonColourRunning = clrRed;

//When Paused
const string ButtonTextPaused = "Paused";
const int ButtonColourPaused = clrAliceBlue;

void CreateButtonPause(){
	ObjectDelete(0, ButtonName);
	ObjectCreate(0, ButtonName, OBJ_BUTTON, 0, 0, 0);
	ObjectSetInteger(0, ButtonName, OBJPROP_XDISTANCE, ButtonXPosition);
	ObjectSetInteger(0, ButtonName, OBJPROP_YDISTANCE, ButtonXPosition);
	ObjectSetInteger(0, ButtonName, OBJPROP_XSIZE,ButtonWidth);
	ObjectSetInteger(0, ButtonName, OBJPROP_YSIZE,ButtonHeight);
	ObjectSetInteger(0, ButtonName, OBJPROP_CORNER, ButtonCorner);
	ObjectSetString(0, ButtonName, OBJPROP_FONT, ButtonFont);
	ObjectSetInteger(0, ButtonName, OBJPROP_FONTSIZE, ButtonFontSize);
	ObjectSetInteger(0, ButtonName, OBJPROP_COLOR, ButtonTextColour);
	
	
	SetButtonState(ButtonState);
	
}

void SetButtonState(bool state) {
	ButtonState = state;
	
	ObjectSetInteger(0, ButtonName, OBJPROP_STATE, ButtonState);
	ObjectSetString(0, ButtonName, OBJPROP_TEXT,ButtonText());
	ObjectSetInteger(0, ButtonName, OBJPROP_BGCOLOR, ButtonColour());
	ChartRedraw(0); // force button to be redrawn once state is changed
	
	
	string msg = StringFormat("%s - %s)", __FUNCSIG__, ButtonText());
	//Comment(msg);
	//Print(msg);
}

string ButtonText() {
	return(ButtonState ? ButtonTextRunning : ButtonTextPaused);
	
}

int ButtonColour(){
	
	return (ButtonState ? ButtonColourRunning : ButtonColourPaused);
	
}