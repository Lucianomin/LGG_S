//+------------------------------------------------------------------+
//|                                                      ProjectName |
//|                                      Copyright 2020, CompanyName |
//|                                       http://www.companyname.net |
//+------------------------------------------------------------------+
#property description "Atentie alegere MaxDdrawdownLoss si Volume"
#property description "Buttons: X-Close All(robot)"
#property description "         E-Close Profitable All(robot)"


#include <Trade/Trade.mqh>
CTrade trade;
//+------------------------------------------------------------------+
//| Inputs                                                           |
//+------------------------------------------------------------------+
input group "----> General Inputs <----";
input long InpMagicNumber=181105;//Magic Number
input int InpMaxNoLacat=3;//Max Number Lacat
input double InpLacatValue=60;//Value Lacat Acivation
input int InpStartLevel=180;//Start Level
input int InpStepLevel=60;//Step Level

input group "----> Volumes Inputs <----";
input double InpVol0=0.01;
input double InpVol1=0.01;
input double InpVol2=0.01;
input double InpVol3=0.02;
input double InpVol4=0.04;
input double InpVol5=0.06;
input double InpVol6=0.1;
input double InpVol7=0.1;
input group "----> Profit Input <----";
input double InpProfit=1;//Profit in dollars
input group "----> Input Sell(if Long) <----";
input double InpVolumeSell=0.32;//Sell Volume from last BUY(lots)
input int InpStepSell=200;//Sell Step from last BUY(pips)
input group "----> Inputs ORDER X  <----";
input double InpOrderXVolume=0.35;//Volume Order X (lots)
input int InpOrderXStep=200;//Step ORDER X(pips)
input bool InpIfHa=true;//Activeaza confirmarea HA False use
input ENUM_TIMEFRAMES InpTimeFrameHa1=PERIOD_M1;//TimeFrame_1 HA
input ENUM_TIMEFRAMES InpTimeFrameHa2=PERIOD_M2;//TimeFrame_2 HA
input ENUM_TIMEFRAMES InpTimeFrameHa3=PERIOD_M3;//TimeFrame_3 HA
input group "----> Time Filter 1<----";
input int InpTimeStartHour = 15;// Start Hour
input int InpTimeStartMin  = 29;//Start Minute
input int InpTimeEndHour   = 20;//End Hour
input int InpTimeEndMin    = 0;//End Minute

input group "----> Time Filter 2<----";
input bool InpSecondTimeFilter=true;//Second Time Filter(optional)
input int InpTimeStartHour1 = 15;// Start Hour
input int InpTimeStartMin1  = 29;//Start Minute
input int InpTimeEndHour1   = 20;//End Hour
input int InpTimeEndMin1    = 0;//End Minute
#define KEY_X 88
#define KEY_E 69
#define KEY_H 72
#define KEY_S 83

double SumBuy,SumSell,SumTotal;
long InpMagicNumber_Copy=InpMagicNumber;
int flag_lacat;
ulong ticketnumber=-1;
double Price_Level=0;
int handleHeikenAshi_1,handleHeikenAshi_2,handleHeikenAshi_3;
int barsTotal_1,barsTotal_2,barsTotal_3;
struct Flags_Heiken_Ashi
  {
   int               sell,buy;
  };
Flags_Heiken_Ashi  flag_HA_1,flag_HA_2,flag_HA_3;

string lastType="BUY";

double g_openBuyVolume = 0.0;
double g_openSellVolume = 0.0;

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit()
  {

   flag_HA_1.buy=0;
   flag_HA_1.sell=0;
   flag_HA_2.buy=0;
   flag_HA_2.sell=0;
   flag_HA_3.buy=0;
   flag_HA_3.sell=0;

   barsTotal_1=iBars(_Symbol,InpTimeFrameHa1);
   barsTotal_2=iBars(_Symbol,InpTimeFrameHa2);
   barsTotal_3=iBars(_Symbol,InpTimeFrameHa3);

   handleHeikenAshi_1= iCustom(_Symbol, InpTimeFrameHa1, "Examples\\Heiken_Ashi.ex5");
   handleHeikenAshi_2= iCustom(_Symbol, InpTimeFrameHa2, "Examples\\Heiken_Ashi.ex5");
   handleHeikenAshi_3= iCustom(_Symbol, InpTimeFrameHa3, "Examples\\Heiken_Ashi.ex5");

   trade.SetExpertMagicNumber(InpMagicNumber_Copy); //Atentie daca vrem sa modificam Magic Number
   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {

  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void  OnChartEvent(const int       id,       const long&     lparam,    const double&   dparam,   const string&   sparam)
  {
   if(id==CHARTEVENT_KEYDOWN)
     {
      if(lparam==KEY_E)
        {
         for(int i=0; i<PositionsTotal(); i++)
           {
            ulong currticket=PositionGetTicket(i);
            ulong magicnumber=PositionGetInteger(POSITION_MAGIC);
            if(PositionSelectByTicket(currticket))
              {
               if(PositionGetDouble(POSITION_PROFIT)>0.01)
                 {
                  if(InpMagicNumber_Copy==magicnumber)
                    {
                     trade.PositionClose(currticket);
                    }
                 }
              }
           }
        }
     }
   if(id==CHARTEVENT_KEYDOWN)
     {
      if(lparam==KEY_X)
        {
         CloseAllPositions();
        }
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTick()
  {

   CountOpenVolumesByType(InpMagicNumber_Copy); // Replace with your desired magic number
   Print("Open BUY volume: ", g_openBuyVolume, " | Open SELL volume: ", g_openSellVolume);

//string lastType = GetLastPositionTypeByMagic(InpMagicNumber_Copy);
   Comment("InpMagicNumber_copy: ",InpMagicNumber_Copy,
           "\nSuma Lot Buy: ",NormalizeDouble(g_openBuyVolume,2),
           "\nSumLotSell: ",NormalizeDouble(g_openSellVolume,2),
           "\nSumaTotal:  ",NormalizeDouble(g_openBuyVolume+g_openSellVolume,2),
           "\nPrice Level current: ",Price_Level,
           "\nLast Type: ",lastType);

//TIMEFILETR
   datetime LocalTime=TimeLocal();

   MqlDateTime DateTimeStructure;
   TimeCurrent(DateTimeStructure);
   DateTimeStructure.sec=0;
   TimeToStruct(LocalTime,DateTimeStructure);

   DateTimeStructure.hour=InpTimeStartHour;
   DateTimeStructure.min=InpTimeStartMin;
   datetime timeStart=StructToTime(DateTimeStructure);

   DateTimeStructure.hour=InpTimeEndHour;
   DateTimeStructure.min=InpTimeEndMin;
   datetime timeEnd=StructToTime(DateTimeStructure);

   DateTimeStructure.hour=InpTimeStartHour1;
   DateTimeStructure.min=InpTimeStartMin1;
   datetime timeStart2=StructToTime(DateTimeStructure);

   DateTimeStructure.hour=InpTimeEndHour1;
   DateTimeStructure.min=InpTimeEndMin1;
   datetime timeEnd2=StructToTime(DateTimeStructure);
   bool isTime = TimeCurrent() >timeStart && TimeCurrent() <timeEnd; //se afla in range
   bool isTime2= TimeCurrent() >timeStart2 && TimeCurrent() <timeEnd2 && InpSecondTimeFilter==true;
   if(isTime==true || isTime2==true)
     {
      if(Check_Activation_Lacat(Check_Open_Buy_Positions(),Check_Open_Sell_Positions())!=1)
        {
         Open_Buy_Sell_Initial(lastType);
         Open_Buy_Sell_Levels(lastType);
         Activate_Sell_at_Step(Check_Open_Buy_Positions(),Check_Open_Sell_Positions(),lastType);
         if(Activate_Order_x(Check_Open_Buy_Positions(),Check_Open_Sell_Positions(),lastType)==1)
           {
            EnterTrade(lastType);
           }
         if(Activate_Order_x(Check_Open_Buy_Positions(),Check_Open_Sell_Positions(),lastType)==2)
           {
            if(SymbolInfoDouble(_Symbol,SYMBOL_ASK)>NormalizeDouble(Price_Level+InpOrderXStep*_Point,_Digits))
              {
               if(trade.Buy(InpOrderXVolume,NULL,SymbolInfoDouble(_Symbol,SYMBOL_ASK),0,0,"ORDER X-LONG"))
                 {
                  lastType="BUY";
                  Print("Order X - placed succesufly");
                 }
              }

           }
         TrailProfitLossWithoutStop(InpProfit,0.5);
        }
      else
        {
         Activate_Lacat_Sleep_Robot();
         SetExpertMagic();
        }
     }
   else
      if(InpProfit<Determine_Account_Profit())
        {
         //lastType=GetLastPositionTypeByMagic(InpMagicNumber_Copy);
         CloseAllPositions();
        }
      else
         if((Check_Open_Buy_Positions()+Check_Open_Sell_Positions())!=0)
           {
            if(Check_Activation_Lacat(Check_Open_Buy_Positions(),Check_Open_Sell_Positions())!=1)
              {
               Open_Buy_Sell_Initial(lastType);
               Open_Buy_Sell_Levels(lastType);
               Activate_Sell_at_Step(Check_Open_Buy_Positions(),Check_Open_Sell_Positions(),lastType);
               if(Activate_Order_x(Check_Open_Buy_Positions(),Check_Open_Sell_Positions(),lastType)==1)
                 {
                  EnterTrade(lastType);
                 }
               if(Activate_Order_x(Check_Open_Buy_Positions(),Check_Open_Sell_Positions(),lastType)==2)
                 {
                  if(SymbolInfoDouble(_Symbol,SYMBOL_ASK)>NormalizeDouble(Price_Level+InpOrderXStep*_Point,_Digits))
                    {
                     if(trade.Buy(InpOrderXVolume,NULL,SymbolInfoDouble(_Symbol,SYMBOL_ASK),0,0,"ORDER X-LONG"))
                       {
                        lastType="BUY";
                        Print("Order X - placed succesufly");
                       }

                    }
                 }
               TrailProfitLossWithoutStop(InpProfit,0.5);
              }
            else
              {
               Activate_Lacat_Sleep_Robot();
               SetExpertMagic();
              }
           }

  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void SetExpertMagic()
  {
   trade.SetExpertMagicNumber(InpMagicNumber_Copy);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int Check_Open_Buy_Positions()
  {
   int cnt=0;
   for(int i=PositionsTotal()-1; i>=0; i--)
     {
      ulong ticket=PositionGetTicket(i);//get ticket
      ulong magicnumber=-1;
      PositionGetInteger(POSITION_MAGIC,magicnumber);
      if(PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY)
        {
         if(InpMagicNumber_Copy==magicnumber)
           {
            cnt++;
           }

        }

     }
   return cnt;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int Check_Open_Sell_Positions()
  {
   int cnt=0;
   for(int i=PositionsTotal()-1; i>=0; i--)
     {
      ulong ticket=PositionGetTicket(i);//get ticket
      ulong magicnumber=-1;
      PositionGetInteger(POSITION_MAGIC,magicnumber);
      if(PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_SELL)
        {
         if(InpMagicNumber_Copy==magicnumber)
           {
            cnt++;
           }

        }

     }
   return cnt;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double Check_Starting_Level()
  {
   double price=-1;
   for(int i=PositionsTotal(); i>=0; i--)
     {
      ulong ticket=PositionGetTicket(i);//get ticket
      ulong magicnumber=-1;
      PositionGetInteger(POSITION_MAGIC,magicnumber);

      if(ticket==ticketnumber)
        {
         if(PositionSelectByTicket(ticket))
           {
            if(InpMagicNumber_Copy==magicnumber)
              {
               price=PositionGetDouble(POSITION_PRICE_OPEN);
              }
           }
        }


     }
   return price;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void Open_Buy_Sell_Initial(string last_pos)
  {
   double ask=NormalizeDouble(SymbolInfoDouble(_Symbol,SYMBOL_ASK),_Digits);
   double bid=NormalizeDouble(SymbolInfoDouble(_Symbol,SYMBOL_BID),_Digits);
   if(last_pos=="BUY")
     {
      if(Check_Open_Buy_Positions()==0)
        {
         if(trade.Buy(InpVol0,NULL,ask,0,0,"BUY_0"))
           {
            ticketnumber=trade.ResultOrder();
            SumBuy=InpVol0;
            SumSell=0;
           }
         else
           {
            //Print("Can not open BUY_0");
           }

        }
      if(Check_Open_Buy_Positions()==1 && Check_Open_Sell_Positions()==0)
        {
         Price_Level=NormalizeDouble(Check_Starting_Level(),_Digits);
         //Print("Starting_level ", Price_Level);
        }
     }
   else ///IMPLEMENTARe pentru sell
      if(last_pos=="SELL")
        {
         if(Check_Open_Sell_Positions()==0)
           {
            if(trade.Sell(InpVol0,NULL,bid,0,0,"SELL_0"))
              {
               ticketnumber=trade.ResultOrder();
               SumSell=InpVol0;
               SumBuy=0;
              }
            else
              {
               //Print("Can not open sell_0");
              }
           }
         if(Check_Open_Sell_Positions()==1 && Check_Open_Buy_Positions()==0)
           {
            Print("GRESSSIT");
            Price_Level=NormalizeDouble(Check_Starting_Level(),_Digits);
            //Print("Starting_level ",Price_Level);
           }
        }

  }
//+------------------------------------------------------------------+
//| Function to get the last opened position type by magic number    |
//+------------------------------------------------------------------+
string GetLastPositionTypeByMagic(long magicNumber)
  {
   int totalPositions = PositionsTotal();
   if(totalPositions == 0)
      return "NONE";

   ulong lastTicket = 0;
   datetime lastTime = 0;

   for(int i = 0; i < totalPositions; i++)
     {
      ulong ticket = PositionGetTicket(i);
      if(PositionSelectByTicket(ticket))
        {
         long posMagic = PositionGetInteger(POSITION_MAGIC);
         if(posMagic == magicNumber)
           {
            datetime openTime = (datetime)PositionGetInteger(POSITION_TIME);
            if(openTime > lastTime)
              {
               lastTime = openTime;
               lastTicket = ticket;
              }
           }
        }
     }

   if(lastTicket != 0 && PositionSelectByTicket(lastTicket))
     {
      ENUM_POSITION_TYPE type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
      if(type == POSITION_TYPE_BUY)
         return "BUY";
      else
         if(type == POSITION_TYPE_SELL)
            return "SELL";
     }

   return "BUY";
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double Determine_Volumes_Mediere(int number)
  {
   double lot = InpVol0; // Default lot size
   switch(number)
     {
      case 0:
         lot = InpVol0; // Lot size for case 1
         break;
      case 1:
         lot = InpVol1; // Lot size for case 1
         break;

      case 2:
         lot = InpVol2; // Lot size for case 2
         break;
      case 3:
         lot = InpVol3; // Lot size for case 1
         break;

      case 4:
         lot = InpVol4; // Lot size for case 2
         break;
      case 5:
         lot = InpVol5; // Lot size for case 2
         break;
      case 6:
         lot = InpVol6; // Lot size for case 1
         break;

      case 7:
         lot = InpVol7; // Lot size for case 2
         break;
      default:
         lot=0;
         break;
     }

   return lot; // Assuming lot is what needs to be returned
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CloseAllPositions()
  {
   for(int i = PositionsTotal(); i >= 0; i--)
     {
      ulong ticket = PositionGetTicket(i);
      if(PositionSelectByTicket(ticket))
        {
         ulong magicnumber = PositionGetInteger(POSITION_MAGIC);
         if(magicnumber == InpMagicNumber_Copy)
           {
            trade.PositionClose(ticket);
           }
        }
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void Open_Buy_Sell_Levels(string last_pos)
  {
   double ask=NormalizeDouble(SymbolInfoDouble(_Symbol,SYMBOL_ASK),_Digits);
   double bid=NormalizeDouble(SymbolInfoDouble(_Symbol,SYMBOL_BID),_Digits);

   if(last_pos=="BUY" && Check_Open_Sell_Positions()==0)
     {
      if(ask<NormalizeDouble(Price_Level-InpStartLevel*_Point,_Digits))
        {
         if(trade.Buy(Determine_Volumes_Mediere(Check_Open_Buy_Positions()),NULL,ask,0,0,"BUYS"))
           {
            Price_Level=NormalizeDouble(Price_Level-InpStepLevel*_Point,_Digits);
            Print(Price_Level);
            SumBuy+=Determine_Volumes_Mediere(Check_Open_Buy_Positions()-1);
           }
         else
           {
            //Print("Can not open BUYS");
           }
        }
     }
   else
      if(last_pos=="SELL" && Check_Open_Buy_Positions()==0)
        {
         if(bid>NormalizeDouble(Price_Level+InpStartLevel*_Point,_Digits))
           {
            if(trade.Sell(Determine_Volumes_Mediere(Check_Open_Sell_Positions()),NULL,bid,0,0,"SELLS"))
              {
               Price_Level=NormalizeDouble(Price_Level+InpStepLevel*_Point,_Digits);
               Print(Price_Level);
               SumBuy+=Determine_Volumes_Mediere(Check_Open_Sell_Positions()-1);
              }
            else
              {

               //Print("Can not open SELLS");
              }
           }
        }

   if(InpProfit<Determine_Account_Profit())
     {
      CloseAllPositions();
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double Determine_Account_Profit()
  {
   double profit = 0.0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      ulong ticket = PositionGetTicket(i);
      if(PositionSelectByTicket(ticket))
        {
         ulong magicnumber = PositionGetInteger(POSITION_MAGIC);
         if(InpMagicNumber_Copy == magicnumber)
           {
            profit += PositionGetDouble(POSITION_PROFIT);
           }
        }
     }
   return profit;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void Activate_Sell_at_Step(int NumarBuysOpen, int NumarSellsOpen, string last_pos)
  {
   double bid=NormalizeDouble(SymbolInfoDouble(_Symbol,SYMBOL_BID),_Digits);
   double ask=NormalizeDouble(SymbolInfoDouble(_Symbol,SYMBOL_ASK),_Digits);
   if(last_pos=="BUY")
     {
      if(NumarBuysOpen==8 && NumarSellsOpen==0)
        {
         //Print("Price_Levele before SELL: ", Price_Level);
         if(bid<NormalizeDouble(Price_Level-(InpStartLevel-InpStepLevel+InpStepSell)*_Point,_Digits))
           {
            if(trade.Sell(InpVolumeSell,NULL,bid,0,0,"Sell Position at Step"))
              {
               Price_Level=NormalizeDouble(Price_Level-(InpStartLevel-InpStepLevel+InpStepSell)*_Point,_Digits);
               Print("Corect Open pos: ", Price_Level);
               SumSell+=InpVolumeSell;
               lastType="SELL";
              }
           }
        }
     }
   else
      if(last_pos=="SELL")
        {
         if(NumarBuysOpen==0 && NumarSellsOpen==8)
           {
            //Print("Price_levels before BUY: ",Price_Level);
            if(ask>NormalizeDouble(Price_Level+(InpStartLevel-InpStepLevel+InpStepSell)*_Point,_Digits))
              {
               if(trade.Buy(InpVolumeSell,NULL,ask,0,0,"Buy Position at Step"))
                 {
                  Price_Level=NormalizeDouble(Price_Level+(InpStartLevel-InpStepLevel+InpStepSell)*_Point,_Digits);
                  Print("Corect open pos: ",Price_Level);
                  SumBuy+=InpVolumeSell;
                  lastType="BUY";
                 }
              }
           }
        }

  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int Activate_Order_x(int NumarBuysOpen, int NumarSellsOpen, string last_pos)
  {
   if(InpIfHa==true)
     {
      if(NumarBuysOpen==8 && NumarSellsOpen==1)
        {return 1;}
      else
         if(NumarSellsOpen==8 && NumarBuysOpen==1)
           {
            return 1;
           }


     }
   else
     {

      if(NumarBuysOpen==8 && NumarSellsOpen==1)
         return 2;
      else
         if(NumarSellsOpen==8 && NumarBuysOpen==1)
           {
            return 2;
           }


     }
   return 0;

  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void EnterTrade(string last_pos)
  {
   double ask=NormalizeDouble(SymbolInfoDouble(_Symbol,SYMBOL_ASK),_Digits);
   double bid=NormalizeDouble(SymbolInfoDouble(_Symbol,SYMBOL_BID),_Digits);

   int bars_1=iBars(_Symbol,InpTimeFrameHa1);
   int bars_2=iBars(_Symbol,InpTimeFrameHa2);
   int bars_3=iBars(_Symbol,InpTimeFrameHa3);


   if(barsTotal_1!=bars_1)
     {
      barsTotal_1=bars_1;

      double haOpen_1[], haClose_1[];

      CopyBuffer(handleHeikenAshi_1,0,1,1,haOpen_1);
      CopyBuffer(handleHeikenAshi_1,3,1,1,haClose_1);

      if(haOpen_1[0]<haClose_1[0])
        {
         //bluecandle
         // if(ask>NormalizeDouble(Price_Level+InpOrderXStep*_Point,_Digits))
         //  {

         flag_HA_1.buy=1;
         // }

        }
      else
         if(haOpen_1[0]>haClose_1[0])
           {

            //if(bid>NormalizeDouble(Price_Level+InpOrderXStep*_Point,_Digits))
            // {
            //redcandle
            flag_HA_1.sell=1;
            // }

           }


      Comment("\nHA Open: ",DoubleToString(haOpen_1[0],_Digits),
              "\nHA Close: ",DoubleToString(haClose_1[0],_Digits)
             );
     }
   if(barsTotal_2!=bars_2)
     {
      barsTotal_2=bars_2;

      double haOpen_2[], haClose_2[];

      CopyBuffer(handleHeikenAshi_1,0,1,1,haOpen_2);
      CopyBuffer(handleHeikenAshi_1,3,1,1,haClose_2);

      if(haOpen_2[0]<haClose_2[0])
        {
         //bluecandle
         //if(ask>NormalizeDouble(Price_Level+InpOrderXStep*_Point,_Digits))
         // {

         flag_HA_2.buy=1;
         // }
        }
      else
         if(haOpen_2[0]>haClose_2[0])
           {

            // if(bid>NormalizeDouble(Price_Level+InpOrderXStep*_Point,_Digits))
            //  {
            //redcandle
            flag_HA_2.sell=1;
            // }

           }


      Comment("\nHA Open: ",DoubleToString(haOpen_2[0],_Digits),
              "\nHA Close: ",DoubleToString(haClose_2[0],_Digits)
             );
     }
   if(barsTotal_3!=bars_3)
     {
      barsTotal_3=bars_3;

      double haOpen_3[], haClose_3[];

      CopyBuffer(handleHeikenAshi_1,0,1,1,haOpen_3);
      CopyBuffer(handleHeikenAshi_1,3,1,1,haClose_3);

      if(haOpen_3[0]<haClose_3[0])
        {
         //bluecandle
         //if(ask>NormalizeDouble(Price_Level+InpOrderXStep*_Point,_Digits))
         //{

         flag_HA_2.buy=1;
         // }
        }
      else
         if(haOpen_3[0]>haClose_3[0])
           {

            //if(bid>NormalizeDouble(Price_Level+InpOrderXStep*_Point,_Digits))
            //{
            //redcandle
            flag_HA_3.sell=1;
            // }

           }


      Comment("\nHA Open: ",DoubleToString(haOpen_3[0],_Digits),
              "\nHA Close: ",DoubleToString(haClose_3[0],_Digits)
             );
     }

//filtru pentru last position buy/sell
   /*double order_x_level=0;
   if(last_pos=="SELL")
     {
      order_x_level=NormalizeDouble(Price_Level+InpOrderXStep*_Point,_Digits);
     }
   else
      if(last_pos=="BUY")
        {
         order_x_level=NormalizeDouble(Price_Level-InpOrderXStep*_Point,_Digits);
        }
        */
//verfify all HA

   if((flag_HA_1.buy==1 && flag_HA_2.buy==1) || (flag_HA_2.buy==1 && flag_HA_3.buy==1) || (flag_HA_1.buy==1 && flag_HA_3.buy==1) ||
      (flag_HA_1.buy==1 && flag_HA_2.buy==1 && flag_HA_3.buy==1))
     {
      if(last_pos=="SELL")
        {
         if(SymbolInfoDouble(_Symbol,SYMBOL_ASK)>NormalizeDouble(Price_Level+InpOrderXStep*_Point,_Digits))
           {
            if(trade.Buy(InpOrderXVolume,NULL,ask,0,0,"HA Buy ORDER X"))
              {
               SumBuy+=InpOrderXVolume;
               flag_HA_1.buy=0;
               flag_HA_2.buy=0;
               flag_HA_3.buy=0;
               lastType="BUY";
              }
           }
        }
      else
         if(last_pos=="BUY")
           {
            if(SymbolInfoDouble(_Symbol,SYMBOL_ASK)<NormalizeDouble(Price_Level-InpOrderXStep*_Point,_Digits))
              {
               if(trade.Buy(InpOrderXVolume,NULL,ask,0,0,"HA Buy ORDER X"))
                 {
                  SumBuy+=InpOrderXVolume;
                  flag_HA_1.buy=0;
                  flag_HA_2.buy=0;
                  flag_HA_3.buy=0;
                  lastType="BUY";
                 }
              }
           }

     }
   if((flag_HA_1.sell==1 && flag_HA_2.sell==1) || (flag_HA_2.sell==1 && flag_HA_3.sell==1) || (flag_HA_1.sell==1 && flag_HA_3.sell==1) ||
      (flag_HA_1.sell==1 && flag_HA_2.sell==1 && flag_HA_3.sell==1))
     {
      if(last_pos=="SELL")
        {
         Print("Aici: ",NormalizeDouble(Price_Level+InpOrderXStep*_Point,_Digits));
         if(SymbolInfoDouble(_Symbol,SYMBOL_BID)>NormalizeDouble(Price_Level+InpOrderXStep*_Point,_Digits))
           {

            if(trade.Sell(InpOrderXVolume,NULL,bid,0,0,"HA Sell ORDER X"))
              {
               SumSell+=InpOrderXVolume;
               flag_HA_1.sell=0;
               flag_HA_2.sell=0;
               flag_HA_3.sell=0;
               lastType="SELL";
              }
           }
        }
      else
         if(last_pos=="BUY")
           {
            if(SymbolInfoDouble(_Symbol,SYMBOL_BID)<NormalizeDouble(Price_Level-InpOrderXStep*_Point,_Digits))
              {
               if(trade.Sell(InpOrderXVolume,NULL,bid,0,0,"HA Sell ORDER X"))
                 {
                  SumSell+=InpOrderXVolume;
                  flag_HA_1.sell=0;
                  flag_HA_2.sell=0;
                  flag_HA_3.sell=0;
                  lastType="SELL";
                 }
              }
           }

     }

  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int Check_Activation_Lacat(int nrS, int nrB)
  {
   int status=-1;
   if(nrB==0 && nrS==0)
     {
      flag_lacat=0;
      status=0;
     }
   if(Determine_Account_Profit()<(-1)*InpLacatValue)
     {
      status=1;
     }
   return status;
  }
//+------------------------------------------------------------------+
//| Count open BUY and SELL volumes into global variables           |
//+------------------------------------------------------------------+
void CountOpenVolumesByType(long magicNumber = -1)
  {
   g_openBuyVolume = 0.0;
   g_openSellVolume = 0.0;

   int totalPositions = PositionsTotal();

   for(int i = 0; i < totalPositions; i++)
     {
      ulong ticket = PositionGetTicket(i);
      if(PositionSelectByTicket(ticket))
        {
         long posMagic = PositionGetInteger(POSITION_MAGIC);

         // If magicNumber is -1, we include all positions
         if(magicNumber == -1 || posMagic == magicNumber)
           {
            double volume = PositionGetDouble(POSITION_VOLUME);
            ENUM_POSITION_TYPE type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);

            if(type == POSITION_TYPE_BUY)
               g_openBuyVolume += volume;
            else
               if(type == POSITION_TYPE_SELL)
                  g_openSellVolume += volume;
           }
        }
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void Activate_Lacat_Sleep_Robot()
  {
   double ask=NormalizeDouble(SymbolInfoDouble(_Symbol,SYMBOL_ASK),_Digits);
   double bid=NormalizeDouble(SymbolInfoDouble(_Symbol,SYMBOL_BID),_Digits);
   double SumLot=0.0;
   SumLot=NormalizeDouble(MathAbs(g_openBuyVolume-g_openSellVolume),2);
   if(g_openBuyVolume-g_openSellVolume<0)
     {
      if(trade.Buy(SumLot,NULL,ask,0,0,"LACAT"))
        {
         SumBuy+=SumLot;
         SendNotification("Lacat Deschis-Robot Sleep");
         flag_lacat=1;
         //lastType="BUY";
         if(InpMagicNumber_Copy-InpMagicNumber<=(InpMaxNoLacat-1))
            InpMagicNumber_Copy++;
        }
     }
   else
      if(g_openBuyVolume-g_openSellVolume>0)
        {
         if(trade.Sell(SumLot,NULL,bid,0,0,"LACAT"))
           {
            SumSell+=SumLot;
            SendNotification("Lacat Deschis-Robot Sleep");
            flag_lacat=1;
            //lastType="SELL";
            if(InpMagicNumber_Copy-InpMagicNumber<(InpMaxNoLacat-1))
               InpMagicNumber_Copy++;
            
           }
        }
   /*if(Check_Open_Buy_Positions()==8 && Check_Open_Sell_Positions()==2 && flag_lacat==0)
     {
      SumLot=(InpVolumeSell+InpOrderXVolume)-(InpVol0+InpVol1+InpVol2+InpVol3+InpVol4+InpVol5+InpVol6+InpVol7);
      if(trade.Buy(SumLot,NULL,ask,0,0,"LACAT"))
        {
         SumBuy+=SumLot;
         SendNotification("Lacat Deschis-Robot Sleep");
         flag_lacat=1;
         if(InpMagicNumber_Copy-InpMagicNumber<=(InpMaxNoLacat-1))
            InpMagicNumber_Copy++;
        }
     }
   else

      if(Check_Open_Buy_Positions()==9 && Check_Open_Sell_Positions()==1 && flag_lacat==0)
        {
         SumLot=(InpVol0+InpVol1+InpVol2+InpVol3+InpVol4+InpVol5+InpVol6+InpVol7+InpOrderXVolume)-InpVolumeSell;
         if(trade.Sell(SumLot,NULL,bid,0,0,"LACAT"))
           {
            SumSell+=SumLot;
            SendNotification("Lacat Deschis-Robot Sleep");
            flag_lacat=1;
            if(InpMagicNumber_Copy-InpMagicNumber<(InpMaxNoLacat-1))
               InpMagicNumber_Copy++;
           }
        }
      else
         if(Check_Open_Buy_Positions()==8 && Check_Open_Sell_Positions()==1 && flag_lacat==0)
           {

            if(InpVolumeSell>(InpVol0+InpVol1+InpVol2+InpVol3+InpVol4+InpVol5+InpVol6+InpVol7))
              {
               SumLot=InpVolumeSell-(InpVol0+InpVol1+InpVol2+InpVol3+InpVol4+InpVol5+InpVol6+InpVol7);
               if(trade.Buy(SumLot,NULL,ask,0,0,"LACAT"))
                 {
                  SumBuy+=SumLot;
                  SendNotification("Lacat Deschis-Robot Sleep");
                  flag_lacat=1;
                  if(InpMagicNumber_Copy-InpMagicNumber<(InpMaxNoLacat-1))
                     InpMagicNumber_Copy++;
                 }
              }
            else
               if(InpVolumeSell<(InpVol0+InpVol1+InpVol2+InpVol3+InpVol4+InpVol5+InpVol6+InpVol7))
                 {
                  SumLot=(InpVol0+InpVol1+InpVol2+InpVol3+InpVol4+InpVol5+InpVol6+InpVol7)-InpVolumeSell;
                  if(trade.Sell(SumLot,NULL,bid,0,0,"LACAT"))
                    {
                     SumSell+=SumLot;
                     SendNotification("Lacat Deschis-Robot Sleep");
                     flag_lacat=1;
                     if(InpMagicNumber_Copy-InpMagicNumber<(InpMaxNoLacat-1))
                        InpMagicNumber_Copy++;
                    }
                 }

           }*/

  }
//+------------------------------------------------------------------+
//| Function to trail P&L and close all positions if conditions met  |
//| Parameters:                                                      |
//|    trailStart - Minimum profit to start trailing                 |
//|    trailStep  - Trailing step for profit threshold               |
//|    Close_All_Positions - External function to close all positions|
//+------------------------------------------------------------------+
void TrailProfitLossWithoutStop(double trailStart, double trailStep)
  {
   static double maxProfit = 0.0; // To track the highest profit

// Update the maximum profit if it exceeds the previous maximum
   if(Determine_Account_Profit() > maxProfit)
     {
      maxProfit = Determine_Account_Profit();
     }

// Check if trailing should be applied
   if(maxProfit >= trailStart)
     {
      double trailingThreshold = maxProfit - trailStep;
      //Print("Trailing active. Max Profit: ", maxProfit, ", Trailing Threshold: ", trailingThreshold);

      // If total profit falls below the trailing threshold, close all positions
      if(Determine_Account_Profit() < trailingThreshold)
        {
         Print("Profit below trailing threshold. Closing all positions.");
         CloseAllPositions();
         maxProfit = 0.0; // Reset maxProfit after closing positions
        }
     }
   else
     {
      //Print("Profit below trail start threshold. No trailing applied.");
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
