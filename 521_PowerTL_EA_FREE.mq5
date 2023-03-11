//+------------------------------------------------------------------+
//|                                                      ProjectName |
//|                                      Copyright 2020, CompanyName |
//|                                       http://www.companyname.net |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------------------+
//|                                                               521_PowerTL_EA |
//|                                  Copyright 2022, www.521StealthAcadem!.com"  |
//|                                             www.521StealthAcadem!.com"       |
//+------------------------------------------------------------------------------+

#property copyright "//t.me/+rr0GLGdADoAxMGFk"
#property link      "//t.me/+rr0GLGdADoAxMGFk"
#property version   "2.00"

#define LIC_PRIVATE_KEY
#define LIC_TRADE_MODE {   ACCOUNT_TRADE_MODE_CONTEST, ACCOUNT_TRADE_MODE_DEMO   }//restrict to Demo account
#define  LIC_EXPIRES_DAYS  21
#define  LIC_EXPIRES_START D'2022.10.09'
#define BtnClose "ButtonClose"
//#define KeyGen

//#define BtnBE "ButtonBE"

#include <trade/trade.mqh>
//input long account = "";
input group    "====== TL name ======"
//input string objName   =  "t";   // Name of trend line

//Input Lot size for the pair
input int      InpMagicNumber    =  202122;      // Magic number
input group "==== Trade Management (R:R= 1:3) ===="
input double Lots = 0;
input int TpPoints = 12000;
input int SlPoints = 4000;
input long Login = "2841584";
//input int NumPosition = 0;

CTrade trade;


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit()
  {
   createButton(BtnClose,"CAP",10,80,45,40,clrWhite,clrRed);//button changed to Bakground
//createButton(BtnBE,"BE",5,105,50,30,clrWhite,clrGreen);
   ChartRedraw();

   if(Login!= 2841584)
     {
      Alert("Wrong Account");
      return (INIT_FAILED);

      //if (Password != "password")  {
      //Alert ("Wrong Password");
      //return (INIT_FAILED);
     }
//else
//return (INIT_FAILED);

   if(!LicenceCheck())
      return (INIT_FAILED);
   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {

   ObjectDelete(0,BtnClose);
//ObjectDelete(0,BtnBE);

  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTick()
  {

   double bid = SymbolInfoDouble(_Symbol,SYMBOL_BID);
   bid = NormalizeDouble(bid,_Digits);
   double ask = SymbolInfoDouble(_Symbol,SYMBOL_ASK);
   ask = NormalizeDouble(ask,_Digits);
   static double lastBid = bid;

   double tpBuy = NormalizeDouble(ask + TpPoints * _Point,_Digits);
   double slBuy = NormalizeDouble(ask - SlPoints * _Point,_Digits);
   double tpSell = NormalizeDouble(bid - TpPoints * _Point,_Digits);
   double slSell = NormalizeDouble(bid + SlPoints * _Point,_Digits);

   string objName = "t";
//name your line as trigger on the chart
   datetime time = TimeCurrent();
//MarketwatchTime
   double price = ObjectGetValueByTime(0,objName,time);
//Comment("Change Line name to trigger, Input Lot size");
   if(bid >= price && lastBid < price)
     {
      SendNotification(StringFormat("%s %s Line touched from BELOW %s",
                                    Symbol(), TimeToString(iTime(Symbol(), Period(), 1)), objName));

      Alert("");
      Alert(StringFormat("%s %s Line touched from BELOW %s",
                         Symbol(), TimeToString(iTime(Symbol(), Period(), 1)), objName));

      trade.Sell(Lots,_Symbol,bid,slSell,tpSell);
      ExpertRemove();
     }
   if(bid <= price && lastBid > price)
     {
      SendNotification(StringFormat("%s %s Line touched from ABOVE %s",
                                    Symbol(), TimeToString(iTime(Symbol(), Period(), 1)), objName));

      Alert("");
      Alert(StringFormat("%s %s Line touched from ABOVE %s",
                         Symbol(), TimeToString(iTime(Symbol(), Period(), 1)), objName));

      trade.Buy(Lots,_Symbol,ask,slBuy,tpBuy);
      ExpertRemove();
     }
   lastBid = bid;
//Comment(price,"\n", bid, "\n", "Change TrendLine name to t and Input Lot size",
//"\n",);
   Comment(price,"\n", bid, "\n", "Change TrendLine name to t and Input Lot size",
           "\n",
           "\n",
           "\n",
           "\n",
           "\n", "|SYMBOL | minLot | maxLot |",
           "\n", "|V10	  -----   	0.3	      	   100   ",
           "\n", "|V25   -----	  0.5	      	   100   ",
           "\n", "|V50   -----	  3	         	   1000  ",
           "\n", "|V75   -----	  0.001      1     ",
           "\n", "|B1k	  -----	    0.2	      	   50    ",
           "\n", "|STEP  -----	  0.1	      	   20    ",
           "\n",
           "\n",
           "\n", "This EA is a trial version");



  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void  OnChartEvent(
   const int       id,       // event ID
   const long&     lparam,   // long type event parameter
   const double&   dparam,   // double type event parameter
   const string&   sparam    // string type event parameter
)
  {

   if(id == CHARTEVENT_OBJECT_CLICK)
     {
      Print("The ",sparam, "was clicked");
      if(sparam == BtnClose)
        {
         for(int i = PositionsTotal()-1; i >= 0; i--)
           {
            ulong posTicket = PositionGetTicket(i);

            if(trade.PositionClose(posTicket))
              {
               Print("Position #",posTicket,"was closed...");
              }

           }
         ObjectSetInteger(0,BtnClose,OBJPROP_STATE,false);


        }

     }

  }


//Create CLOSE ALL Button
bool createButton(string objName, string text, int x, int y, int width, int height, color clrTxt, color clrBg)
  {

   ResetLastError();
   if(!ObjectCreate(0,objName,OBJ_BUTTON,0,0,0))
     {
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


//Licence check
bool LicenceCheck()
  {
//bool LicenceCheck(string licence="");  {

   bool valid = false;

#ifdef LIC_EXPIRES_DAYS
#ifndef LIC_EXPIRES_START
#define LIC_EXPIRES_START  __DATETIME__
#endif

   datetime expiredDate =  LIC_EXPIRES_START + (LIC_EXPIRES_DAYS*86400);
   PrintFormat("Time limited copy, licence expires at %s", TimeToString(expiredDate));
   Comment("Time limited copy, licence expires at %s", TimeToString(expiredDate));
   if(TimeCurrent()>expiredDate)
     {
      Print("Licence has expired");
      Alert("Licence has expired");
      return(false);
     }
#endif

#ifdef LIC_TRADE_MODE
   valid = false;
   int validModes[]  = LIC_TRADE_MODE;
   long accountTradeMode = AccountInfoInteger(ACCOUNT_TRADE_MODE);
   for(int i=ArraySize(validModes)-1; i>=0; i--)
     {
      if(accountTradeMode==validModes[i])
        {
         valid = true;
         break;
        }
     }
   if(!valid)
     {
      Print("this is a limited trial version, will not work on REAL accounts");
      return(false);
     }
#endif

   /*
   #ifdef LIC_PRIVATE_KEY
      long  account  =  AccountInfoInteger(ACCOUNT_LOGIN);
      //string result  =  IntegerToString(account);

      if (account = ACCOUNT_LOGIN) {

         return(true);

      }else return(false);//Print("Invalid licence");
         //Print ("Account number Should be " + account);

   #endif

   */

   return(true);

  }
//+------------------------------------------------------------------+
