//+------------------------------------------------------------------+
//|                                                  FxToad.mq5      |
//|                        Copyright 2010, Fxtoad.                   |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2010, FxToad."
#property version   "1.00"
#include <trade/trade.mqh>
CTrade trade;

//--- input parameters
input int GridSize= 100;
input int NumberOfGrid= 20;
input double GridEffect = 2;
input double TakeProfit = 20;
input double StopLoss =    0;
input double StartLot = 0.01;
//--- Other parameters
MqlTick latest_price;

bool middle_of_transaction=false;
int EA_Magic=999999;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   
   return(0);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
   
   //--- Get the last price quote using the MQL5 MqlTick Structure
   if(!SymbolInfoTick(_Symbol,latest_price))
     {
      Alert("Error getting the latest price quote - error:",GetLastError(),"!!");
      return;
     }
     if (!middle_of_transaction)
    {
    if (getCountOfOpenPosition(POSITION_TYPE_BUY)==1 && getCountOfLimitOrders(ORDER_TYPE_BUY_LIMIT)==0)
       for (int i=0;i<NumberOfGrid;i++)
        OpenBuyLimit(i+1);
 
   if (getCountOfOpenPosition(POSITION_TYPE_SELL)==1 && getCountOfLimitOrders(ORDER_TYPE_SELL_LIMIT)==0)    
       for (int i=0;i<NumberOfGrid;i++)
        OpenSellLimit(i+1);
   checkTPandClose();    
   if (getCountOfOpenPosition(POSITION_TYPE_BUY)==0)
      OpenOrder(ORDER_TYPE_BUY);
   if (getCountOfOpenPosition(POSITION_TYPE_SELL)==0)
      OpenOrder(ORDER_TYPE_SELL);

   
    }


   return;
  }
  int getCountOfLimitOrders(ENUM_ORDER_TYPE otype)
  {
    int i=OrdersTotal()-1;
    int count=0;
   while (i>=0)
   {
     OrderSelect(OrderGetTicket(i));
     if (OrderGetInteger(ORDER_TYPE)==otype) count++;
     i--;
     
   }
   return count;
  }
  int getCountOfOpenPosition(ENUM_POSITION_TYPE postype)
  {
   int i=PositionsTotal()-1;
   int count=0;
   while (i>=0)
   {
   PositionSelectByTicket(PositionGetTicket(i));
   if (PositionGetInteger(POSITION_TYPE)==postype)
      count++;
   i--;
   }
   return count;
  }
  double PositionsTotalProfit(ENUM_POSITION_TYPE position_type)
  {
   double Total_Profit=0;
   double deal_commission=0;
   double deal_fee=0;
   double deal_profit=0;
   int total=PositionsTotal();
   for(int i=0; i<total; i++)
     {
      ulong  position_ticket=PositionGetTicket(i);                                      // ticket of the position
      ulong  magic=PositionGetInteger(POSITION_MAGIC);                                  // MagicNumber of the position
      string comment=PositionGetString(POSITION_COMMENT);                               // position comment
      long   position_ID=PositionGetInteger(POSITION_IDENTIFIER);                         // Identifier of the position
      ENUM_POSITION_TYPE cur_pos_type = PositionGetInteger(POSITION_TYPE);

      //if(magic==EXPERT_MAGIC || comment==IntegerToString(EXPERT_MAGIC))
        /*{
         HistorySelect(0,TimeCurrent());
         int deals=HistoryOrdersTotal();
         for(int j=deals-1; j>=0; j--)
           {
            ulong deal_ticket=HistoryDealGetTicket(j);
            if(HistoryDealGetInteger(deal_ticket,DEAL_POSITION_ID) == position_ID)
              {
               deal_profit=HistoryDealGetDouble(deal_ticket, DEAL_PROFIT);
               deal_commission=HistoryDealGetDouble(deal_ticket, DEAL_COMMISSION)*2;
               deal_fee=HistoryDealGetDouble(deal_ticket, DEAL_FEE);
               break;
              }
           }
         //Total_Profit += PositionGetDouble(POSITION_PROFIT) + PositionGetDouble(POSITION_SWAP) + deal_profit + deal_commission + deal_fee;
         
        }*/
        if (cur_pos_type==position_type)
         Total_Profit += PositionGetDouble(POSITION_PROFIT);
     }
   return(Total_Profit);
  }
void checkTPandClose()
{
   middle_of_transaction= true;
   if (TakeProfit*StartLot*10<PositionsTotalProfit(POSITION_TYPE_BUY) ||
   (getCountOfLimitOrders(ORDER_TYPE_BUY_LIMIT)>0 && getCountOfOpenPosition(POSITION_TYPE_BUY)==0 )
   )
            closeAllPositions("buy");
   if (TakeProfit*StartLot*10<PositionsTotalProfit(POSITION_TYPE_SELL) ||
   (getCountOfLimitOrders(ORDER_TYPE_SELL_LIMIT)>0 && getCountOfOpenPosition(POSITION_TYPE_SELL)==0 )
   )
            closeAllPositions("sell");
   middle_of_transaction=false;
}
void closeAllPositions(string postype)
{
  int i=PositionsTotal()-1;
  
   while (i>=0)
   {
   PositionSelectByTicket(PositionGetTicket(i));
   if ((postype=="buy" && PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY) ||
      (postype=="sell" && PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_SELL))
   {
      trade.PositionClose(PositionGetTicket(i),5); 
   }
    i--;
     
   }
   i=OrdersTotal()-1;
   while (i>=0)
   {
     OrderSelect(OrderGetTicket(i));
     if ((postype=="buy" && OrderGetInteger(ORDER_TYPE)==ORDER_TYPE_BUY_LIMIT) ||
      (postype=="sell" && OrderGetInteger(ORDER_TYPE)==ORDER_TYPE_SELL_LIMIT))
      {
      trade.OrderDelete(OrderGetTicket(i)); 
      }
      i--;
   } 
 }
void OpenBuyLimit(int gridnum)
{
         MqlTradeRequest mrequest;  // To be used for sending our trade requests
         MqlTradeResult mresult;    // To be used to get our trade results
         MqlRates mrate[];          // To be used to store the prices, volumes and spread of each bar
         ZeroMemory(mrequest);      // Initialization of mrequest structure
         double open_price=0;
         double stop_loss=0;
         double take_profit=0;
       
       
                  
         for (int i=0;i<PositionsTotal();i++)         
         {
             PositionSelectByTicket(PositionGetTicket(i));
             if (PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY)
               break;
         }
         double already_opened_price = PositionGetDouble(POSITION_PRICE_OPEN);
         stop_loss = PositionGetDouble(POSITION_SL);
         double already_opened_volume = PositionGetDouble(POSITION_VOLUME);
         open_price = already_opened_price - (GridSize/MathPow(10,_Digits )*10)*gridnum;
         double Lot = NormalizeDouble(already_opened_volume*MathPow(GridEffect,gridnum),2);
         if (Lot>100) Lot=100;
         mrequest.action = TRADE_ACTION_PENDING;                                  // immediate order execution
         mrequest.price = NormalizeDouble(open_price,_Digits);           // latest ask price
         mrequest.sl = NormalizeDouble(stop_loss,_Digits); // Stop Loss
         mrequest.tp = NormalizeDouble(take_profit,_Digits); // Take Profit
         mrequest.symbol = _Symbol;                                            // currency pair
         mrequest.volume = Lot;                                                 // number of lots to trade
         mrequest.magic = EA_Magic;                                             // Order Magic Number
         mrequest.type = ORDER_TYPE_BUY_LIMIT;                                        // Buy Order
         mrequest.type_filling = ORDER_FILLING_FOK;                             // Order execution type
         mrequest.deviation=100;                                                // Deviation from current price
         //--- send order
         OrderSend(mrequest,mresult);
         // get the result code
         if(mresult.retcode==10009 || mresult.retcode==10008) //Request is completed or order placed
           {
            Alert("A Buy order has been successfully placed with Ticket#:",mresult.order,"!!");
           }
         else
           {
            Alert("The Buy order request could not be completed -error:",GetLastError());
            ResetLastError();           
            return;
           }
}

void OpenSellLimit(int gridnum)
{
         MqlTradeRequest mrequest;  // To be used for sending our trade requests
         MqlTradeResult mresult;    // To be used to get our trade results
         MqlRates mrate[];          // To be used to store the prices, volumes and spread of each bar
         ZeroMemory(mrequest);      // Initialization of mrequest structure
         double open_price=0;
         double stop_loss=0;
         double take_profit=0;
         
         for (int i=0;i<PositionsTotal();i++)         
         {
             PositionSelectByTicket(PositionGetTicket(i));
             if (PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_SELL)
               break;
         }
         double already_opened_price = PositionGetDouble(POSITION_PRICE_OPEN);
         stop_loss = PositionGetDouble(POSITION_SL);
         double already_opened_volume = PositionGetDouble(POSITION_VOLUME);
         open_price = already_opened_price + (GridSize/MathPow(10,_Digits )*10)*gridnum;
         double Lot = NormalizeDouble(already_opened_volume*MathPow(GridEffect,gridnum),2);
         if (Lot>100) Lot=100;
         mrequest.action = TRADE_ACTION_PENDING;                                  // immediate order execution
         mrequest.price = NormalizeDouble(open_price,_Digits);           // latest ask price
         mrequest.sl = NormalizeDouble(stop_loss,_Digits); // Stop Loss
         mrequest.tp = NormalizeDouble(take_profit,_Digits); // Take Profit
         mrequest.symbol = _Symbol;                                            // currency pair
         mrequest.volume = Lot;                                                 // number of lots to trade
         mrequest.magic = EA_Magic;                                             // Order Magic Number
         mrequest.type = ORDER_TYPE_SELL_LIMIT;                                 // SeLL Order
         mrequest.type_filling = ORDER_FILLING_FOK;                             // Order execution type
         mrequest.deviation=100;                                                // Deviation from current price
         //--- send order
         
         OrderSend(mrequest,mresult);
         // get the result code
        int  err = GetLastError();
         if(mresult.retcode==10009 || mresult.retcode==10008) //Request is completed or order placed
           {
            Alert("A Sell order has been successfully placed with Ticket#:",mresult.order,"!!");
           }
         else
           {
            Alert("The Sell order request could not be completed -error:",GetLastError());
            ResetLastError();           
            return;
           }

}
double realDouble(double x)
{
   return NormalizeDouble(x,_Digits);
}
void OpenOrder(ENUM_ORDER_TYPE actiontype)
{
        MqlTradeRequest mrequest;  // To be used for sending our trade requests
         MqlTradeResult mresult;    // To be used to get our trade results
         MqlRates mrate[];          // To be used to store the prices, volumes and spread of each bar
         ZeroMemory(mrequest);      // Initialization of mrequest structure
       
         
         mrequest.action = TRADE_ACTION_DEAL;                                  // immediate order execution
         if (actiontype==ORDER_TYPE_BUY)
            mrequest.price = NormalizeDouble(latest_price.ask,_Digits);           // latest ask price
         if (actiontype==ORDER_TYPE_SELL)
            mrequest.price = NormalizeDouble(latest_price.bid,_Digits);           // latest ask price
         
         if (actiontype==ORDER_TYPE_BUY)
              mrequest.tp = realDouble(realDouble(latest_price.ask)+realDouble(TakeProfit*10/MathPow(10,_Digits ))); // Stop Loss   
         if (actiontype==ORDER_TYPE_SELL)
              mrequest.tp = realDouble(realDouble(latest_price.bid)-realDouble(TakeProfit*10/MathPow(10,_Digits ))); // Stop Loss   
         
         if (actiontype==ORDER_TYPE_BUY)
              mrequest.sl = realDouble(realDouble(latest_price.ask)-realDouble(StopLoss*10/MathPow(10,_Digits ))); // Stop Loss   
         if (actiontype==ORDER_TYPE_SELL)
              mrequest.sl = realDouble(realDouble(latest_price.bid)+realDouble(StopLoss*10/MathPow(10,_Digits ))); // Stop Loss   
              if (StopLoss==0)
               mrequest.sl=0;
         //mrequest.tp = NormalizeDouble(take_profit,_Digits); // Take Profit
         mrequest.symbol = _Symbol;                                            // currency pair
         mrequest.volume = StartLot;                                      // number of lots to trade
         mrequest.magic = 99999;                                            // Order Magic Number
         mrequest.type = actiontype;                                        // Buy Order
         mrequest.type_filling = ORDER_FILLING_FOK;                             // Order execution type
         mrequest.deviation=100;                                                // Deviation from current price
         //--- send order
         OrderSend(mrequest,mresult);
         // get the result code
         if(mresult.retcode==10009 || mresult.retcode==10008) //Request is completed or order placed
         {
            Alert("An order has been successfully placed with Ticket#:",mresult.order,"!!");
         }
         else
         {
            Alert("The order request could not be completed -error:",GetLastError());
            ResetLastError();           
            return;
         }
}
