import SwiftUI

struct ProfileAnalyticsView: View {
    @StateObject private var analyticsService = MoodAnalyticsService()
    @State private var selectedPeriod: AnalyticsPeriod = .week
    private let daysOrder = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
    
    var body: some View {
        ZStack {
                        
            VStack(spacing: 8) {
                
                //Picker
                HStack(spacing: 4) {
                    ForEach(AnalyticsPeriod.allCases, id: \.self) { period in
                        Button(action: {
                            if(selectedPeriod != period){
                                selectedPeriod = period
                                analyticsService.fetchAnalytics(period: period)
                            }
                        }) {
                            Text(formattedPeriodTitle(period.rawValue).capitalized)
                                .padding(.vertical, 6)
                                .font(.custom("Georgia", size: 10))
                                .frame(minWidth: 0, maxWidth: .infinity)
                                .fontWeight(selectedPeriod == period ? .bold : .medium)
                                .foregroundColor(selectedPeriod == period ? .pink : .white.opacity(0.6))
                                .background(
                                    ZStack {
                                        Capsule()
                                            .fill(Color.pink.opacity(0.2))
                                            .opacity(selectedPeriod == period ? 1 : 0)
                                        
                                        Capsule()
                                            .stroke(selectedPeriod == period ? Color.pink : Color.gray.opacity(0.3), lineWidth: 1)
                                    }
                                    .animation(.easeInOut(duration: 0.5), value: selectedPeriod == period)
                                )
                        }
                        .background(Color.white.opacity(0.05))
                        .clipShape(Capsule())
                    }
                }
                .padding(.top, 8)
                                
                // Content Area
                ScrollView {
                    if analyticsService.isLoading {
                        ProgressView("Loading analytics...")
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .padding(.top, 20)
                    } else if let errorMessage = analyticsService.errorMessage {
                        VStack(spacing: 10) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.largeTitle)
                                .foregroundColor(.orange)
                            Text("Error Loading Analytics")
                                .font(.headline)
                                .foregroundColor(.white)
                            Text(errorMessage)
                                .font(.caption)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                            Button("Retry") {
                                analyticsService.fetchAnalytics(period: selectedPeriod)
                            }
                            .padding(.top)
                            .buttonStyle(.borderedProminent)
                            .tint(.pink)
                        }
                        .padding(.top, 50)
                        .padding(.horizontal, 20)
                    } else if let analytics = analyticsService.analyticsData {
                        analyticsContent(analytics)
                            .padding(.bottom, 80)
                    } else {
                        Text("No analytics data available for the selected period.")
                            .foregroundColor(.gray)
                            .padding(.top, 50)
                            .padding(.horizontal, 20)
                    }
                }
            }
        }
        .onAppear {
            analyticsService.fetchAnalytics(period: selectedPeriod)
        }
    }
    
    @ViewBuilder
    private func analyticsContent(_ data: AnalyticsData) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            /*
            if let startDate = data.dateRange.start, let endDate = data.dateRange.end {
                let dateFormatter: DateFormatter = {
                    let formatter = DateFormatter()
                    formatter.dateStyle = .medium
                    return formatter
                }()
                Text("Displaying data for: \(dateFormatter.string(from: startDate)) - \(dateFormatter.string(from: endDate))")
                    .font(.custom("Georgia", size: 14))
                    .foregroundColor(.white.opacity(0.7))
            }*/

            overallAverageMoodMimicSection(data.averageMoodForPeriod, periodName: data.period.capitalized)
            Divider().background(Color.white.opacity(0.5))
            moodByDayOfWeekSection(data.averageMoodByDayOfWeek)
        }
    }
    
    private func formattedPeriodTitle(_ rawPeriodName: String) -> String {
        if rawPeriodName.lowercased() == AnalyticsPeriod.threeMonths.rawValue {
            return "3 Months"
        }else if rawPeriodName.lowercased() == AnalyticsPeriod.all.rawValue{
            return "All Time"
        } else {
            return (rawPeriodName)
        }
    }
    
    @ViewBuilder
    private func overallAverageMoodMimicSection(_ summary: MoodPeriodSummary, periodName: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            if(formattedPeriodTitle(periodName)=="All Time"){
                Text("All Time")
                    .font(.custom("Georgia", size: 24))
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
            }else if(formattedPeriodTitle(periodName)=="3 Months"){
                Text("These \(formattedPeriodTitle(periodName))")
                    .font(.custom("Georgia", size: 24))
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
            }else{
                Text("This \(formattedPeriodTitle(periodName))")
                    .font(.custom("Georgia", size: 24))
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
            }

            let averageEmotionForChart = Emotion(
                name: summary.topEmotion ?? "Average",
                color: EmotionColorMap.getColor(for: summary.topEmotion ?? "Neutral"),
                description: "Average mood attributes for the period.",
                pleasantness: summary.averageAttributes.pleasantness ?? 0.5,
                intensity: summary.averageAttributes.intensity ?? 0.5,
                control: summary.averageAttributes.control ?? 0.5,
                clarity: summary.averageAttributes.clarity ?? 0.5
            )
            
            VStack(spacing: 0) {
                HStack {
                    Text("Average Attributes")
                        .font(.custom("Georgia", size: 16))
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    Spacer()
                }
                .padding()
                EmotionRadarChartView(emotion: averageEmotionForChart, showText: true)
                    .offset(y: -10)
            }
            .frame(maxWidth: .infinity, idealHeight: 280, maxHeight: 300)
            .background(Color.white.opacity(0.05))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(averageEmotionForChart.color.opacity(0.6), lineWidth: 2)
            )
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                VStack(spacing: 8) {
                    Text(summary.topEmotion ?? "N/A")
                        .font(.custom("Georgia", size: 20))
                        .fontWeight(.bold)
                        .foregroundColor(EmotionDataProvider.getEmotion(byName: summary.topEmotion ?? "Neutral")?.color )
                    
                    Text("Top Emotion")
                        .font(.custom("Georgia", size: 14))
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity)
                .padding(16)
                .background(Color.white.opacity(0.05))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(EmotionColorMap.getColor(for: summary.topEmotion ?? "Neutral").opacity(0.6), lineWidth: 2)
                )
                
                VStack(spacing: 8) {
                    Text("\(summary.totalCheckins)")
                        .font(.custom("Georgia", size: 20))
                        .fontWeight(.bold)
                        .foregroundColor(EmotionDataProvider.getEmotion(byName: summary.topEmotion ?? "Neutral")?.color )
                    
                    Text("Check-Ins")
                        .font(.custom("Georgia", size: 14))
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity)
                .padding(16)
                .background(Color.white.opacity(0.05))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(averageEmotionForChart.color.opacity(0.6), lineWidth: 2)
                )
            }
        }
    }
    
    @ViewBuilder
    private func dayDetailContent(for dayName: String, from summaries: [MoodDaySummary]) -> some View {
        if let summary = summaries.first(where: { $0.dayOfWeek == dayName }) {
            DetailedDailyMoodCardView(daySummary: summary)
                .padding(.bottom, 5)
        } else {
            VStack(alignment: .leading) {
                Text(dayName)
                    .font(.custom("Georgia", size: 18).bold())
                    .foregroundColor(.gray)
                Text("No check-ins for this day.")
                    .font(.custom("Chivo", size: 14))
                    .foregroundColor(.gray)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white.opacity(0.03))
            .cornerRadius(12)
            .padding(.bottom, 5)
        }
    }
    
    @ViewBuilder
    private func moodByDayOfWeekSection(_ dailySummaries: [MoodDaySummary]) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Daily Breakdown:")
                .font(.custom("Georgia", size: 20))
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            let sortedSummaries = dailySummaries.sorted { $0.dayNumber < $1.dayNumber }
            
            ForEach(daysOrder, id: \.self) { dayName in
                self.dayDetailContent(for: dayName, from: sortedSummaries)
            }
        }
    }
}
