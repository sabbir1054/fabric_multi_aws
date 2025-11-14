import {
    Context,
    Contract,
    Info,
    Returns,
    Transaction,
} from 'fabric-contract-api';

interface TimeSeriesPoint {
    timestamp: string;
    pH: number;
    Moisture: number;
    nh4: number;
    doValue: number;
    ca: number;
    temp: number;
    salinity: number;
}

@Info({
    title: 'SensorContract',
    description: 'Smart contract for conflict-free water sensor data ingestion',
})
export class SensorContract extends Contract {
    @Transaction()
    @Returns('string')
    public async addBatchSensorReadings(
        ctx: Context,
        jsonData: string,
        timestamp: string
    ): Promise<string> {
        interface Reading {
            SensorID: string;
            Temp: string;
            Salinity: string;
            PH: string;
            NH4: string;
            DO: string;
            CA: string;
        }

        let readings: Reading[];
        try {
            readings = JSON.parse(jsonData);
        } catch {
            throw new Error('Invalid JSON format for sensor readings batch.');
        }

        let count = 0;

        for (const r of readings) {
            if (
                !r.SensorID ||
                !r.Temp ||
                !r.PH ||
                !r.DO ||
                !r.NH4 ||
                !r.CA ||
                !r.Salinity
            )
                continue;

            const parsed = {
                temp: parseFloat(r.Temp),
                pH: parseFloat(r.PH),
                doValue: parseFloat(r.DO),
                nh4: parseFloat(r.NH4),
                ca: parseFloat(r.CA),
                salinity: parseFloat(r.Salinity),
                Moisture: parseFloat(r.Temp),
            };

            const weight = this.calculateWeight(
                parsed.temp,
                parsed.pH,
                parsed.doValue,
                parsed.nh4,
                parsed.ca,
                parsed.salinity
            );

            const keySuffix = `${timestamp}-${count}`;

            const readingKey = ctx.stub.createCompositeKey('SENSOR_READING', [
                r.SensorID,
                keySuffix,
            ]);
            const weightKey = ctx.stub.createCompositeKey('WEIGHT_POOL_LOG', [
                r.SensorID,
                keySuffix,
            ]);
            const graphKey = ctx.stub.createCompositeKey('GRAPH_VIEW_LOG', [
                r.SensorID,
                keySuffix,
            ]);
            const activityKey = ctx.stub.createCompositeKey(
                'NODE_ACTIVITY_LOG',
                [r.SensorID, keySuffix]
            );

            await ctx.stub.putState(
                readingKey,
                Buffer.from(
                    JSON.stringify({
                        sensorId: r.SensorID,
                        score: weight,
                        timestamp,
                        ...parsed,
                    })
                )
            );

            await ctx.stub.putState(
                weightKey,
                Buffer.from(
                    JSON.stringify({
                        delta: weight > 0 ? -100 : 50,
                        timestamp,
                    })
                )
            );

            await ctx.stub.putState(
                graphKey,
                Buffer.from(JSON.stringify({ timestamp, ...parsed }))
            );

            await ctx.stub.putState(
                activityKey,
                Buffer.from(JSON.stringify({ timestamp }))
            );

            count++;
        }

        return `✅ Micro-batch processed ${count} readings (fully conflict-free).`;
    }

    @Transaction(false)
    @Returns('string')
    public async getWeightPool(ctx: Context): Promise<string> {
        const iterator = await ctx.stub.getStateByPartialCompositeKey(
            'WEIGHT_POOL_LOG',
            []
        );
        let total = 50000;
        let result = await iterator.next();

        while (!result.done) {
            const log = JSON.parse(result.value.value.toString());
            total += log.delta;
            result = await iterator.next();
        }
        await iterator.close();

        return JSON.stringify({
            value: total,
            lastUpdated: new Date().toString(),
        });
    }

    // ✅ NEW METHOD: Return weight pool changes over time for chart
    @Transaction(false)
    @Returns('string')
    public async getWeightPoolOverTime(ctx: Context): Promise<string> {
        const iterator = await ctx.stub.getStateByPartialCompositeKey(
            'WEIGHT_POOL_LOG',
            []
        );

        const records: { timestamp: string; delta: number }[] = [];

        let result = await iterator.next();
        while (!result.done) {
            const data = JSON.parse(result.value.value.toString());
            records.push({
                timestamp: data.timestamp,
                delta: data.delta,
            });
            result = await iterator.next();
        }
        await iterator.close();

        // Sort by timestamp
        records.sort(
            (a, b) =>
                new Date(a.timestamp).getTime() -
                new Date(b.timestamp).getTime()
        );

        const output: { time: number; weight: number }[] = [];
        let total = 50000;
        for (let i = 0; i < records.length; i++) {
            total += records[i].delta;
            output.push({ time: i + 1, weight: total });
        }

        return JSON.stringify(output);
    }

    @Transaction(false)
    @Returns('string')
    public async getRankedSensors(ctx: Context): Promise<string> {
        const iterator = await ctx.stub.getStateByPartialCompositeKey(
            'SENSOR_READING',
            []
        );
        const sensorScores: Record<string, { total: number; count: number }> =
            {};

        let result = await iterator.next();
        while (!result.done) {
            const record = JSON.parse(result.value.value.toString());
            const { sensorId, score } = record;
            if (!sensorScores[sensorId]) {
                sensorScores[sensorId] = { total: 0, count: 0 };
            }
            sensorScores[sensorId].total += score;
            sensorScores[sensorId].count += 1;

            result = await iterator.next();
        }
        await iterator.close();

        const rankings = Object.entries(sensorScores).map(
            ([sensorId, { total, count }]) => ({
                sensorId,
                totalScore: total,
                readingCount: count,
                averageScore: total / count,
            })
        );

        rankings.sort((a, b) => b.averageScore - a.averageScore);
        return JSON.stringify(rankings);
    }

    @Transaction(false)
    @Returns('string')
    public async getGraphViewBySensor(
        ctx: Context,
        sensorId: string
    ): Promise<string> {
        const iterator = await ctx.stub.getStateByPartialCompositeKey(
            'GRAPH_VIEW_LOG',
            [sensorId]
        );
        const graphData: TimeSeriesPoint[] = [];
        let result = await iterator.next();

        while (!result.done) {
            const record = JSON.parse(
                result.value.value.toString()
            ) as TimeSeriesPoint;
            graphData.push(record);
            result = await iterator.next();
        }
        await iterator.close();

        graphData.sort(
            (a, b) =>
                new Date(a.timestamp).getTime() -
                new Date(b.timestamp).getTime()
        );
        return JSON.stringify(graphData);
    }

    @Transaction(false)
    @Returns('string')
    public async getSensorAveragesByKeyword(
        ctx: Context,
        keyword: string
    ): Promise<string> {
        const normalized = keyword.toLowerCase();
        const keyMap: Record<string, keyof TimeSeriesPoint> = {
            temp: 'temp',
            ph: 'pH',
            do: 'doValue',
            nh4: 'nh4',
            ca: 'ca',
            salinity: 'salinity',
            moisture: 'Moisture',
        };

        const field = keyMap[normalized];
        if (!field) {
            throw new Error(`Invalid keyword: ${keyword}`);
        }

        const iterator = await ctx.stub.getStateByPartialCompositeKey(
            'GRAPH_VIEW_LOG',
            []
        );
        const sensorData: Record<string, { total: number; count: number }> = {};

        let result = await iterator.next();
        while (!result.done) {
            const compositeKey = ctx.stub.splitCompositeKey(result.value.key);
            const sensorId = compositeKey.attributes[0];

            const data = JSON.parse(
                result.value.value.toString()
            ) as TimeSeriesPoint;
            const value = data[field];

            if (typeof value === 'number') {
                if (!sensorData[sensorId]) {
                    sensorData[sensorId] = { total: 0, count: 0 };
                }
                sensorData[sensorId].total += value;
                sensorData[sensorId].count += 1;
            }

            result = await iterator.next();
        }
        await iterator.close();

        const resultArray = Object.entries(sensorData).map(
            ([sensorId, { total, count }]) => ({
                sensorId,
                average: parseFloat((total / count).toFixed(2)),
            })
        );

        return JSON.stringify(resultArray);
    }

    @Transaction(false)
    @Returns('string')
    public async getNodeActivityOverTime(ctx: Context): Promise<string> {
        const iterator = await ctx.stub.getStateByPartialCompositeKey(
            'NODE_ACTIVITY_LOG',
            []
        );
        const activityLog: { time: string; nodeId: string }[] = [];

        let result = await iterator.next();
        while (!result.done) {
            const compositeKey = ctx.stub.splitCompositeKey(result.value.key);
            const nodeId = compositeKey.attributes[0];
            const { timestamp } = JSON.parse(result.value.value.toString());
            activityLog.push({ time: timestamp, nodeId });
            result = await iterator.next();
        }
        await iterator.close();

        activityLog.sort(
            (a, b) => new Date(a.time).getTime() - new Date(b.time).getTime()
        );

        return JSON.stringify(activityLog);
    }

    private calculateWeight(
        temp: number,
        ph: number,
        doValue: number,
        nh4: number,
        ca: number,
        salinity: number
    ): number {
        let score = 0;
        if (temp >= 20 && temp <= 30) score++;
        else score--;
        if (ph >= 6.5 && ph <= 8.5) score++;
        else score--;
        if (doValue >= 5 && doValue <= 12) score++;
        else score--;
        if (nh4 >= 0 && nh4 <= 50) score++;
        else score--;
        if (ca >= 3 && ca <= 10) score++;
        else score--;
        if (salinity >= 0 && salinity <= 0.5) score++;
        else score--;

        return score;
    }
}
