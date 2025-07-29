# Stock Option Trading Rules and Data Requirements

This document outlines the comprehensive data requirements and trading rules for the TastyTrades Option Trader system.

## Data Categories for Analysis

### 1. Fundamental Data Points

#### Core Financial Metrics
- **Earnings Per Share (EPS)** - Quarterly and annual
- **Revenue** - Top-line growth metrics
- **Net Income** - Bottom-line profitability
- **EBITDA** - Operating performance measure

#### Valuation Ratios
- **Price-to-Earnings (P/E) Ratio** - Current and forward
- **Price/Sales Ratio** - Revenue-based valuation
- **PEG Ratio** - Growth-adjusted P/E with forward estimates
- **Free Cash Flow Yield** - Cash generation efficiency

#### Profitability Metrics
- **Gross Margins** - Product/service profitability
- **Operating Margins** - Operational efficiency

#### Market Intelligence
- **Insider Transactions** - Buy/sell activity patterns
- **Forward Guidance** - Management outlook
- **Sell-side Blended Multiples** - Analyst consensus valuations
- **Insider-sentiment Analytics** - In-depth behavioral analysis

### 2. Options Chain Data Points

#### Greeks and Pricing
- **Implied Volatility (IV)** - Market expectation of price movement
- **Delta** - Price sensitivity to underlying movement
- **Gamma** - Rate of delta change
- **Theta** - Time decay
- **Vega** - Volatility sensitivity
- **Rho** - Interest rate sensitivity

#### Market Structure
- **Open Interest** - By strike and expiration
- **Volume** - By strike and expiration
- **Skew/Term Structure** - Volatility smile analysis
- **IV Rank/Percentile** - Based on 52-week IV history

#### Advanced Analytics
- **Real-time Option Chains** - Updates < 1 minute
- **Weekly/Deep OTM Strikes** - Extended chain coverage
- **Dealer Gamma/Charm Exposure Maps** - Market maker positioning
- **Professional IV Surface** - 3D volatility visualization
- **Minute-level IV Percentile** - High-frequency volatility tracking

### 3. Price & Volume Historical Data Points

#### Standard Technical Indicators
- **Daily OHLCV** - Open, High, Low, Close, Volume
- **Historical Volatility** - Realized price movement
- **Moving Averages** - 50/100/200-day trends
- **Average True Range (ATR)** - Volatility measure
- **Relative Strength Index (RSI)** - Momentum oscillator
- **MACD** - Trend following indicator
- **Bollinger Bands** - Volatility bands
- **VWAP** - Volume-Weighted Average Price
- **Pivot Points** - Support/resistance levels

#### High-Frequency Data
- **Intraday OHLCV** - 1-minute/5-minute intervals
- **Tick-level Prints** - Every trade execution
- **Real-time Consolidated Tape** - All exchange data
- **Price-momentum Metrics** - Acceleration indicators

### 4. Alternative Data Points

#### Social and Sentiment
- **Social Sentiment** - Twitter/X, Reddit analysis
- **News Event Detection** - Headline parsing
- **Google Trends** - Search interest patterns
- **Paid Social-sentiment Aggregates** - Professional sentiment feeds

#### Economic Activity
- **Credit-card Spending Trends** - Consumer behavior
- **Geolocation Foot Traffic** - Placer.ai data
- **Satellite Imagery** - Parking lot counts
- **App-download Trends** - Sensor Tower data
- **Job Postings Feeds** - Hiring activity
- **Large-scale Product-pricing Scrapes** - Competitive intelligence

### 5. Macro Indicator Data Points

#### Economic Indicators
- **Consumer Price Index (CPI)** - Inflation measure
- **GDP Growth Rate** - Economic expansion
- **Unemployment Rate** - Labor market health
- **Nonfarm Payrolls** - Job creation
- **Retail Sales Reports** - Consumer spending

#### Market Indicators
- **10-year Treasury Yields** - Risk-free rate
- **Volatility Index (VIX)** - Market fear gauge
- **ISM Manufacturing Index** - Economic activity
- **Consumer Confidence Index** - Sentiment measure

#### Real-time Data
- **Live FOMC Minute Text** - Fed policy updates
- **Real-time Treasury Futures** - Rate expectations
- **SOFR Curve** - Interest rate term structure

### 6. ETF & Fund Flow Data Points

#### Daily Flow Metrics
- **SPY & QQQ Daily Flows** - Major index tracking
- **Sector-ETF Inflows/Outflows** - XLK, XLF, XLE, etc.
- **ETF Short Interest** - Bearish positioning

#### Institutional Activity
- **Hedge-fund 13F Filings** - Quarterly holdings
- **Institutional Ownership Changes** - Large position shifts
- **Intraday ETF Creation/Redemption** - Authorized participant activity

#### Market Structure
- **Leveraged-ETF Rebalance Estimates** - End-of-day flows
- **Large Redemption Notices** - Liquidity events
- **Index-reconstruction Announcements** - Rebalancing impacts

### 7. Analyst Rating & Revision Data Points

#### Consensus Metrics
- **Consensus Target Price** - Average analyst price target
- **Recent Upgrades/Downgrades** - Rating changes
- **New Coverage Initiations** - Fresh analyst perspectives

#### Estimate Revisions
- **Earnings Estimate Revisions** - EPS forecast changes
- **Revenue Estimate Revisions** - Top-line adjustments
- **Margin Estimate Changes** - Profitability outlook
- **Full Sell-side Model Revisions** - Comprehensive updates

#### Market Intelligence
- **Short Interest Updates** - Bearish positioning
- **Recommendation Dispersion** - Analyst disagreement

## Trade Selection Criteria

### Portfolio Parameters
- **Number of Trades**: Exactly 5 trades per selection cycle
- **Account NAV**: $100,000 base calculation
- **Objective**: Maximize edge while maintaining risk limits

### Hard Filters (Mandatory Requirements)

All trades must meet these criteria or be discarded:

1. **Quote Freshness**
   - Quote age ≤ 10 minutes
   - Real-time data required

2. **Probability of Profit (POP)**
   - Top option POP ≥ 0.65 (65%)
   - Based on current market conditions

3. **Risk/Reward Ratio**
   - Credit received / max loss ≥ 0.33
   - Minimum 1:3 risk/reward

4. **Position Sizing**
   - Max loss per trade ≤ 0.5% of NAV
   - For $100k account: max loss ≤ $500

### Selection Rules

1. **Ranking System**
   - Primary: Rank trades by model_score
   - Secondary: Momentum_z score
   - Tertiary: Flow_z score

2. **Diversification Requirements**
   - Maximum 2 trades per GICS sector
   - Avoid concentration risk

3. **Portfolio Greeks Constraints**
   - **Delta Limits**: Net basket delta between [-0.30, +0.30] × (NAV / 100k)
   - **Vega Limits**: Net basket vega ≥ -0.05 × (NAV / 100k)

4. **Tie-Breaking Rules**
   - Prefer higher momentum_z scores
   - Then prefer higher flow_z scores
   - Consider liquidity metrics

### Output Format Requirements

Generate trade recommendations in the following table format:

| Ticker | Strategy | Legs | Thesis | POP |
|--------|----------|------|--------|-----|
| AAPL | Iron Condor | 150/155/165/170 | High IV rank with range-bound price action expected through earnings | 72% |
| MSFT | Put Credit Spread | 340/335 | Strong support at 340, bullish momentum in tech sector | 68% |

#### Format Guidelines
- **Ticker**: Stock symbol only
- **Strategy**: Standard option strategy name
- **Legs**: Strike prices for all legs
- **Thesis**: Maximum 30 words, plain language
- **POP**: Percentage format

### Trading Rules and Constraints

#### Entry Rules
1. All trades must be entered during regular market hours
2. Use limit orders only (no market orders)
3. Verify real-time quotes before submission
4. Check for earnings/dividend dates

#### Risk Management
1. **Stop Loss**: Exit if position reaches 2× credit received
2. **Profit Target**: Close at 50% of max profit
3. **Time Stop**: Manage at 21 DTE regardless of P&L
4. **Event Risk**: Close before binary events

#### Portfolio Management
1. **Maximum Positions**: 20 concurrent trades
2. **Buying Power Usage**: ≤ 50% of available
3. **Correlation Limits**: Monitor sector exposure
4. **VaR Constraint**: 1-day VaR ≤ 2% of NAV

### Execution Guidelines

#### Order Placement
1. **Spread Width**: Use standard strikes when possible
2. **Fill Improvement**: Start at mid-price, walk towards natural
3. **Partial Fills**: Accept if ≥ 50% of intended size
4. **Time Limits**: Cancel unfilled orders after 5 minutes

#### Trade Monitoring
1. **Real-time P&L**: Track mark-to-market continuously
2. **Greeks Monitoring**: Alert on significant changes
3. **News Monitoring**: Check for breaking events
4. **Technical Levels**: Watch support/resistance

### Compliance and Reporting

#### Trade Documentation
- Record entry time, price, and rationale
- Document any deviations from rules
- Track actual vs. expected outcomes

#### Performance Metrics
- **Win Rate**: Target ≥ 65%
- **Average Winner/Loser Ratio**: Target ≥ 1.5
- **Sharpe Ratio**: Target ≥ 1.0
- **Maximum Drawdown**: Limit to 10%

### System Responses

#### Insufficient Trades
If fewer than 5 trades meet all criteria:
- **Response**: "Fewer than 5 trades meet criteria, do not execute."
- **Action**: Wait for next analysis cycle
- **Documentation**: Log market conditions preventing trades

#### Error Handling
1. **Data Quality Issues**: Flag and exclude affected symbols
2. **Calculation Errors**: Fail safely, log for review
3. **Connectivity Problems**: Pause trading, alert operator

## Implementation Notes

### Data Pipeline Requirements
1. Establish real-time data feeds for all categories
2. Implement data quality checks and validation
3. Create fallback data sources for redundancy
4. Monitor data latency and accuracy

### Model Integration
1. Build scoring models using all data categories
2. Backtest selection criteria on historical data
3. Implement real-time model updates
4. Track model performance and drift

### System Architecture
1. Separate data collection from analysis
2. Implement parallel processing for speed
3. Use message queues for reliability
4. Build comprehensive logging system

### Operational Procedures
1. Daily system health checks
2. Weekly performance reviews
3. Monthly strategy adjustments
4. Quarterly system audits