


//+------------------------------------------------------------------+
//|                                                   521_DHL_EA.mq5 |
//|                                Copyright 2022, 521StealthAcadem! |
//|                                   https://t.me/+rr0GLGdADoAxMGFk |
//+------------------------------------------------------------------+
#property copyright "//t.me/+rr0GLGdADoAxMGFk"
#property link      "//t.me/+rr0GLGdADoAxMGFk"
#property version   "1.00"
#property indicator_separate_window 
#property indicator_buffers 1 
#property indicator_plots   1

#include <Trade\Trade.mqh>
CTrade trade;

//Input parameters 
input group "==== Volumes ===="

input double      Lots = 0;  //Lot Size
input int         TP = 0;
input int         SL = 0;
input int         InpMagicNumber = 54321;    //Magic Number

//input bool        IsHammer = false;  //
//input bool        IsEngulfing = false;  //
//input bool        Scalper   =  true;   //
input bool        IsTrailing = true;

double ask = SymbolInfoDouble(_Symbol,SYMBOL_ASK);
//ask = NormalizeDouble(ask,_Digits);
double bid = SymbolInfoDouble(_Symbol,SYMBOL_BID);
//bid = NormalizeDouble(bid,_Digits);
//double tpBuy   =  NormalizeDouble(ask + TP * _Point,_Digits);
//double tpSell  =  NormalizeDouble(bid - TP * _Point,_Digits);
//double slBuy   =  NormalizeDouble(ask - SL * _Point,_Digits);
//double slSell  =  NormalizeDouble(bid + SL * _Point,_Digits);

ulong posTicket;

int stHandle;
int rsiHandle;
int StochHandle;

int TotalBars;
double lastBid;
int barsTotalD1;

//string objName = "t";

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+

int OnInit()   {

   
   
   lastBid  =  SymbolInfoDouble(_Symbol,SYMBOL_BID);
   TotalBars  =  iBars(_Symbol,PERIOD_H1);
   
   rsiHandle = iRSI(_Symbol, PERIOD_H1,14,PRICE_CLOSE);
   StochHandle = iStochastic(_Symbol,PERIOD_H1,14,3,3,MODE_SMA,STO_LOWHIGH);
   
   //Print(rsi[0]);
   
   
   
   getHlcSignal();
     
	   
   ChartRedraw();
   
   return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason)  {

}
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+

void OnTick()  {
   int barsD1   =  iBars(_Symbol,PERIOD_D1);
      if(barsTotalD1 != barsD1)  {
         barsTotalD1 =  barsD1;
      Print(__FUNCTION__," > Reset"); 
      }
      
      double st[];
      CopyBuffer(stHandle,0,0,3,st);
      
      double rsi[];
      CopyBuffer(rsiHandle,0,1,1,rsi);
      
      double stoch_H1[];
      CopyBuffer(StochHandle,0,1,1,stoch_H1);
      
      double   highD1  =  iHigh(_Symbol,PERIOD_D1,1);
      double   lowD1   =  iLow(_Symbol,PERIOD_D1,1);
      double   highD2  =  iHigh(_Symbol,PERIOD_D1,2);
      double   lowD2   =  iLow(_Symbol,PERIOD_D1,2);
      
      
      double tpBuy   =  NormalizeDouble(ask + TP * _Point,_Digits);
      double tpSell  =  NormalizeDouble(bid - TP * _Point,_Digits);
      double slBuy   =  NormalizeDouble(ask - SL * _Point,_Digits);
      double slSell  =  NormalizeDouble(bid + SL * _Point,_Digits);
      string objName = "trigger";
      //name your line as trigger on the chart
      datetime time = TimeCurrent();
      //MarketwatchTime
      double price = ObjectGetValueByTime(0,objName,time);
      
      int bars = iBars(_Symbol,PERIOD_H1);
      if(TotalBars != bars){
      //TotalBars = bars;
      int HLCC = getHlcSignal();
      
      //if(Scalper){
         
            if(stoch_H1[0] >= 75 && HLCC > 0){// && bid > highD1){//(rsi [0] > 30 || rsi [0] < 49)  && stoch_H1[0] <= 25){
            //Comment (ask: "");
              
               //if(bid > highD1){ //&& ask <= highD1){
               //Comment(highD1);

               int highBar = iHighest(_Symbol, PERIOD_H1, MODE_HIGH,2,0);
               double slS = iHigh(_Symbol, PERIOD_H1,highBar);
               //datetime time  =  iTime(_Symbol,PERIOD_H1,1);
      
            
               trade.Sell(Lots,_Symbol,bid,(slS + SL *_Point),0, "Sell Scalp");
              
               
               Print(" %s Sell Scalp ", Symbol());
               Alert("");
               Alert(StringFormat(" %s Sell Scalp ", Symbol()));
               SendNotification(StringFormat(" %s Sell Scalp", Symbol()));
               TotalBars = bars;
             //}
               
            }else if(stoch_H1[0] <= 25 && HLCC < 0){// && ask < lowD1){//(rsi [0] > 50 || rsi [0] < 70) && stoch_H1[0] >= 75){
            
               //if(ask < lowD1){ //&& bid >= lowD1){
              // Comment(lowD1);
              
         
               int lowBar = iLowest(_Symbol, PERIOD_H1, MODE_LOW,2,0);
               double slB = iLow(_Symbol, PERIOD_H1,lowBar);
               //datetime time  =  iTime(_Symbol,PERIOD_H1,1);
            
               trade.Buy(Lots,_Symbol,ask,(slB - SL * _Point),0,"Buy Scalp");
               
               Print(" %s Buy Scalp ", Symbol());
               Alert("");
               Alert(StringFormat(" %s Buy Scalp ", Symbol()));
               SendNotification(StringFormat(" %s Buy Scalp ", Symbol()));
               TotalBars = bars;
            //}
            

			   
            }  
         //}
      //}
      
         int lowBar = iLowest(_Symbol, PERIOD_H4, MODE_LOW,2,0);
         double slB = iLow(_Symbol, PERIOD_H4,lowBar);
         int highBar = iHighest(_Symbol, PERIOD_H4, MODE_HIGH,2,0);
         double slS = iHigh(_Symbol, PERIOD_H4,highBar);
   
      
       if(IsTrailing) { /// Tight and agressive trailing stop... gets out too early, on first pull backs
     
            for(int i = PositionsTotal()-1; i >= 0; i--)
              {
               posTicket = PositionGetTicket(i);
               CPositionInfo  pos;
               if(pos.SelectByTicket(posTicket))
                 {
                  if(pos.PositionType() == POSITION_TYPE_BUY)
                    {
                     if(slBuy > pos.StopLoss())
                       {
                        trade.PositionModify(posTicket,slB,pos.TakeProfit());
                       }
                    }
                  else
                     if(pos.PositionType() == POSITION_TYPE_SELL)
                       {
      
                        if(slSell < pos.StopLoss())
                          {
                           trade.PositionModify(posTicket,slS,pos.TakeProfit());
                          }
                       }
                 }
              }
     }
             
   }
}
  

        

int getHlcSignal()   {
   datetime time  =  iTime(_Symbol,PERIOD_CURRENT,1);
   
   double   high1  =  iHigh(_Symbol,PERIOD_CURRENT,1);
   double   low1   =  iLow(_Symbol,PERIOD_CURRENT,1);
   double   open1  =  iOpen(_Symbol,PERIOD_CURRENT,1);
   double   close1 =  iClose(_Symbol,PERIOD_CURRENT,1);

   double   high2  =  iHigh(_Symbol,PERIOD_CURRENT,2);
   double   low2  =  iLow(_Symbol,PERIOD_CURRENT,2);
   double   open2  =  iOpen(_Symbol,PERIOD_CURRENT,2);
   double   close2 =  iClose(_Symbol,PERIOD_CURRENT,2);
   
   
   //bullish HHHC formation
   if(close1 > high2 && high1 > high2 )   {
      createObj(time,low1,241,1,clrGreen,"HHHC");
      return 1;    
   }

   //bullish LLLC formation
   if(close1 < low2 && low1 < low2)   {
      createObj(time,high1,242,-1,clrRed,"LLLC");
      return -1;    
   } 
   return 0; //No pattern found
} 

//
//Engulfing candles//
//
//int getEngulfingSignal()   {
//   datetime time  =  iTime(_Symbol,PERIOD_CURRENT,1);
//   
//   double   high1  =  iHigh(_Symbol,PERIOD_CURRENT,1);
//   double   low1   =  iLow(_Symbol,PERIOD_CURRENT,1);
//   double   open1  =  iOpen(_Symbol,PERIOD_CURRENT,1);
//   double   close1 =  iClose(_Symbol,PERIOD_CURRENT,1);
//
//   double   high2  =  iHigh(_Symbol,PERIOD_CURRENT,2);
//   double   low2  =  iLow(_Symbol,PERIOD_CURRENT,2);
//   double   open2  =  iOpen(_Symbol,PERIOD_CURRENT,2);
//   double   close2 =  iClose(_Symbol,PERIOD_CURRENT,2);
//   
//   
//   bullish engulfing formation
//   if(open1 <  close1){
//      if(open2 >  close2){
//         if(high1 >  high2 && low1  <  low2){
//            if(close1 > open2 && open1 < close2){
//               createObj(time,low1,241,1,clrGreen,"Engulfing");
//               return 1;
//            }
//         }      
//      }  
//   }
//
//   bearish engulfing formation
//   if(open1 >  close1){
//      if(open2 <  close2){
//         if(high1 >  high2  && low1  <  low2){
//            if(close1 < open2 && open1 > close2){
//               createObj(time,high1,242,-1,clrRed,"Engulfing");
//               return -1;
//            } 
//         }      
//      }  
//   }
//   
//   return 0; //No pattern found
//
//}
//
//int getHammerSignal(double maxRatioShortShadow, double minRatioLongShadow){
//   datetime time  =  iTime(_Symbol,PERIOD_CURRENT,1);
//   
//   double   high  =  iHigh(_Symbol,PERIOD_CURRENT,1);
//   double   low   =  iLow(_Symbol,PERIOD_CURRENT,1);
//   double   open  =  iOpen(_Symbol,PERIOD_CURRENT,1);
//   double   close =  iClose(_Symbol,PERIOD_CURRENT,1);
//   
//   double candleSize =  high-low;
//   
//   green hammer buy calculation
//   if(open < close){
//      if(high - close < candleSize * maxRatioShortShadow){
//         if(open - low > candleSize * minRatioLongShadow){
//            createObj(time,low,242,1,clrGreen,"Hammer");
//            return 1;
//         }
//      } 
//   }
//     
//   red hammer sell calculation
//   if(open > close){
//      if(close - low < candleSize * maxRatioShortShadow){
//         if(high - open > candleSize * minRatioLongShadow){
//            createObj(time,high,242,-1,clrRed,"Hammer");
//            return -1;
//         }
//      }
//   }
//   
//     green hammer sell calculation
//   if(open < close){
//      if(open - low < candleSize * maxRatioShortShadow){
//         if(high - close > candleSize * minRatioLongShadow){
//            createObj(time,high,242,-1,clrRed,"Hammer");
//            return -1;
//         }
//      }
//   }
//   
//   red hammer buy calculation
//   if(open > close){
//      if(high - open < candleSize * maxRatioShortShadow){
//         if(close - low > candleSize * minRatioLongShadow){
//            createObj(time,low,242,1,clrGreen,"Hammer");
//            return 1;
//         }
//      }
//   }
//   return 0; //No pattern found
//}

/////Create Object 

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
      ObjectSetInteger(0,objNameDesc,OBJPROP_COLOR,clr);
      if (direction > 0) ObjectSetInteger(0,objNameDesc,OBJPROP_ANCHOR,ANCHOR_TOP);
      if (direction < 0) ObjectSetInteger(0,objNameDesc,OBJPROP_ANCHOR,ANCHOR_BOTTOM);
   }

}
